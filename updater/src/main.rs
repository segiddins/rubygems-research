use openssl::sha::Sha256;
use serde::{self};
use std::{
    borrow::Borrow,
    fmt::Debug,
    fs,
    io::{self, Write},
    time::Duration,
};
use tar;

struct Sha256Sum {
    sum: [u8; 32],
}

impl Debug for Sha256Sum {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(&hex::encode(&self.sum))
    }
}

impl serde::Serialize for Sha256Sum {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_str(&hex::encode(&self.sum))
    }
}

impl From<[u8; 32]> for Sha256Sum {
    fn from(sum: [u8; 32]) -> Self {
        Sha256Sum { sum }
    }
}

impl From<Sha256> for Sha256Sum {
    fn from(sha256: Sha256) -> Self {
        Sha256Sum {
            sum: sha256.finish().into(),
        }
    }
}

#[derive(Debug, serde::Serialize, Default)]
struct Blob {
    sha256: Sha256Sum,
    size: u64,

    contents: Vec<u8>,
}

impl Blob {
    fn from_reader<R: std::io::Read>(reader: &mut R) -> Result<Self, Error> {
        let mut writer = BlobWriter::default();
        io::copy(reader, &mut writer)?;
        Ok(writer.into())
    }
}

const EMPTY_SHA256: Sha256Sum = Sha256Sum {
    sum: [
        0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14, 0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f, 0xb9,
        0x24, 0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c, 0xa4, 0x95, 0x99, 0x1b, 0x78, 0x52,
        0xb8, 0x55,
    ],
};

impl Default for Sha256Sum {
    fn default() -> Self {
        EMPTY_SHA256
    }
}

#[derive(Default)]
struct BlobWriter {
    sha256: Sha256,
    contents: Vec<u8>,
}

impl std::io::Write for BlobWriter {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        let len = self.contents.write(&buf)?;
        if len > 0 {
            self.sha256.update(&buf[..len]);
        }
        Ok(len)
    }

    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}

impl From<BlobWriter> for Blob {
    fn from(writer: BlobWriter) -> Blob {
        let len = writer.contents.len() as u64;
        Blob {
            sha256: writer.sha256.into(),
            contents: writer.contents,
            size: len,
        }
    }
}

// impl<R: std::io::Read> TryFrom<&mut R> for Blob {
//     fn try_from(&mut reader: R) -> Result<Self, Self::Error> {
//         let mut writer = BlobWriter::default();
//         io::copy(&mut reader, &mut writer)?;
//         Ok(writer.into())
//     }

//     type Error = Error;
// }

struct BlobTeeWriter<R: std::io::Read> {
    reader: R,
    blob_writer: BlobWriter,
}

impl<R: std::io::Read> BlobTeeWriter<R> {
    fn new(reader: R) -> Self {
        BlobTeeWriter {
            reader,
            blob_writer: Default::default(),
        }
    }
}

impl<R: std::io::BufRead> std::io::Read for BlobTeeWriter<R> {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        let n = self.reader.read(buf)?;
        assert_eq!(n, self.blob_writer.write(&buf[..n])?);
        Ok(n)
    }
}

impl<R: std::io::BufRead> std::io::BufRead for BlobTeeWriter<R> {
    fn fill_buf(&mut self) -> io::Result<&[u8]> {
        self.reader.fill_buf()
    }

    fn consume(&mut self, amt: usize) {
        self.reader.consume(amt)
    }
}

#[derive(Debug, serde::Serialize)]
struct Entry {
    path: String,
    blob: Blob,
    mode: u32,
    linkname: String,
    uid: u64,
    gid: u64,
}

#[derive(Debug)]
enum Error {
    Io(io::Error),
    EntrySizeMismatch(u64, u64),
    InvalidTarPath(String),
}

impl From<io::Error> for Error {
    fn from(e: io::Error) -> Self {
        Error::Io(e)
    }
}

#[derive(Debug, serde::Serialize)]
struct Package {
    path: String,
    dot_gem: Blob,
    metadata: Blob,
    entries: Vec<Entry>,
}

impl Package {
    fn new(path: String) -> Self {
        Self {
            path,
            dot_gem: Default::default(),
            metadata: Default::default(),
            entries: Default::default(),
        }
    }
}

impl<'a, R: std::io::Read> TryFrom<&mut tar::Entry<'a, R>> for Entry {
    fn try_from(value: &mut tar::Entry<'a, R>) -> Result<Self, Self::Error> {
        let blob = Blob::from_reader(value)?;
        let path = value
            .path()?
            .to_str()
            .map(|s| s.to_string())
            .ok_or_else(|| Error::InvalidTarPath(format!("{:?}", &value.header()).to_string()))?;
        let linkname = value
            .header()
            .link_name()?
            .map(|s| s.to_str().unwrap_or_default().to_string())
            .unwrap_or_default();
        Ok(Entry {
            path,
            blob,
            mode: value.header().mode()?,
            linkname,
            uid: value.header().uid()?,
            gid: value.header().gid()?,
        })
    }

    type Error = Error;
}

fn enumerate_package(path: String) -> Result<Package, Error> {
    let mut reader = io::BufReader::new(fs::File::open(&path)?);
    let mut r = BlobTeeWriter::new(&mut reader);

    let mut archive = tar::Archive::new(&mut r);

    let mut package = Package::new(path);

    for entry in archive.entries()? {
        match entry {
            Err(e) => return Err(e.into()),
            Ok(mut entry) => match entry.header().path_bytes().borrow() as &[u8] {
                b"metadata.gz" => {
                    package.metadata = Blob::from_reader(&mut entry)?;
                }
                b"data.tar.gz" => {
                    enumerate_data_tar_gz(entry, &mut package)?;
                }
                _ => {}
            },
        }
    }

    package.dot_gem = r.blob_writer.into();

    Ok(package)
}

fn enumerate_data_tar_gz<R: std::io::BufRead>(
    mut entry: tar::Entry<'_, R>,
    package: &mut Package,
) -> Result<(), Error> {
    let mut archive = tar::Archive::new(flate2::read::GzDecoder::new(&mut entry));
    let entries = archive.entries()?.map(|e| Entry::try_from(&mut e?));
    Ok(for entry in entries {
        package.entries.push(entry?);
    })
}

fn main() {
    let mut entries =
        fs::read_dir("/Users/segiddins/Development/github.com/akr/gem-codesearch/mirror/gems/")
            .unwrap()
            .map(|res| res.unwrap().path().to_str().unwrap().to_string())
            .collect::<Vec<_>>();
    entries.sort_unstable();
    let total = entries.len();
    let mut underlying = entries.into_iter().map(enumerate_package);

    let start = std::time::Instant::now();

    println!("[{:?}] Start", start);

    let mut n = 0;
    loop {
        let group = Iterator::take(&mut underlying, 10000).collect::<Vec<Result<Package, Error>>>();
        if group.len() == 0 {
            break;
        }

        let errors = group
            .iter()
            .filter_map(|r| r.as_ref().err())
            .collect::<Vec<_>>();

        n += group.len();
        let now = std::time::Instant::now();
        let elapsed = now - start;
        let rate: f64 = n as f64 / elapsed.as_secs_f64();
        let expected: Duration = Duration::from_secs_f64(total as f64 / rate);
        println!(
            "[{:?}] {:?} Processed {} packages ({}), expected: {:?}",
            now, elapsed, n, rate, expected
        );
        errors.iter().for_each(|e| println!("\t{:?}", e));
        if n >= 50000 {
            break;
        }
    }
}

package pipes

import (
	"context"
	"runtime/trace"
	"sync"

	"golang.org/x/sync/semaphore"
)

type Pipe[O any] struct {
	output chan O
	err    error
	done   chan struct{}
}

func newPipe[I any, O any](pipe *Pipe[I]) *Pipe[O] {
	if pipe.err != nil {
		return &Pipe[O]{nil, pipe.err, pipe.done}
	}
	return &Pipe[O]{make(chan O), nil, pipe.done}
}

func copyError[I any, O any](pipe *Pipe[I], ret *Pipe[O]) {
	if ret.err != nil {
		return
	}
	ret.err = pipe.err
}

func Map[I any, O any](pipe *Pipe[I], f func(I) (O, error)) (ret *Pipe[O]) {
	ret = newPipe[I, O](pipe)
	if ret.err != nil {
		return ret
	}
	go func() {
		defer trace.StartRegion(context.Background(), "Pipe.Map").End()
		defer close(ret.output)
		defer copyError(pipe, ret)
		for i := range pipe.output {
			o, err := f(i)
			if err != nil {
				ret.err = err
				return
			}
			ret.output <- o
		}
	}()
	return
}

func FlatMap[I any, O any](pipe *Pipe[I], f func(I) ([]O, error)) (ret *Pipe[O]) {
	ret = newPipe[I, O](pipe)
	if ret.err != nil {
		return ret
	}
	go func() {
		defer trace.StartRegion(context.Background(), "Pipe.FlatMap").End()
		defer close(ret.output)
		defer copyError(pipe, ret)
		for i := range pipe.output {
			o, err := f(i)
			if err != nil {
				ret.err = err
				return
			}
			for _, v := range o {
				ret.output <- v
			}
		}
	}()
	return
}

func ConcurrentMap[I any, O any](pipe *Pipe[I], f func(I) (O, error), concurrency int) (ret *Pipe[O]) {
	ret = newPipe[I, O](pipe)
	if ret.err != nil {
		return ret
	}
	go func() {
		defer trace.StartRegion(context.Background(), "Pipe.ConcurrentMap").End()
		defer close(ret.output)
		defer copyError(pipe, ret)

		concurrency := int64(concurrency)
		sema := semaphore.NewWeighted(concurrency)
		m := sync.Mutex{}
		defer sema.Acquire(context.Background(), concurrency)

		for {
			if ret.err != nil {
				return
			}
			select {
			case <-pipe.done:
			case <-ret.done:
				return
			case i, ok := <-pipe.output:
				if !ok {
					return
				}
				if err := sema.Acquire(context.Background(), 1); err != nil {
					m.Lock()
					defer m.Unlock()
					ret.err = err
					return
				}
				go func(i I) {
					defer sema.Release(1)
					o, err := f(i)
					if err != nil {
						m.Lock()
						defer m.Unlock()
						ret.err = err
						return
					}

					m.Lock()
					defer m.Unlock()
					ret.output <- o
				}(i)
			}
		}
	}()
	return
}

func (pipe *Pipe[I]) Err() error {
	return pipe.err
}

func (pipe *Pipe[O]) Limit(n int) (ret *Pipe[O]) {
	ret = newPipe[O, O](pipe)
	if ret.err != nil {
		return
	}
	go func() {
		defer trace.StartRegion(context.Background(), "Pipe.Limit").End()
		defer close(ret.output)
		defer copyError(pipe, ret)
		for i := range pipe.output {
			if n <= 0 {
				return
			}
			n--
			ret.output <- i
		}
	}()
	return
}

func (pipe *Pipe[O]) Collect() (ret []O, err error) {
	defer trace.StartRegion(context.Background(), "Pipe.Collect").End()
	defer close(pipe.done)
	for i := range pipe.output {
		ret = append(ret, i)
	}
	err = pipe.err
	return
}

// Filter returns a new pipe that only contains elements that satisfy the predicate.
func (pipe *Pipe[O]) Filter(f func(O) bool) (ret *Pipe[O]) {
	ret = newPipe[O, O](pipe)
	if ret.err != nil {
		return
	}
	go func() {
		defer close(ret.output)
		defer copyError(pipe, ret)
		for i := range pipe.output {
			if f(i) {
				ret.output <- i
			}
		}
	}()

	return
}

func (pipe *Pipe[O]) ForEach(f func(O) error) error {
	defer trace.StartRegion(context.Background(), "Pipe.ForEach").End()
	defer close(pipe.done)
	for i := range pipe.output {
		if err := f(i); err != nil {
			return err
		}
	}
	return pipe.err
}

func From[T any](i ...T) (ret *Pipe[T]) {
	ret = &Pipe[T]{make(chan T), nil, make(chan struct{})}
	go func() {
		defer close(ret.output)
		for _, v := range i {
			select {
			case <-ret.done:
				return
			case ret.output <- v:
			}
		}
	}()
	return
}

func Reduce[I any, O any](pipe *Pipe[I], f func(O, I) (O, error), initial O) (ret *Pipe[O]) {
	ret = newPipe[I, O](pipe)
	if ret.err != nil {
		return
	}
	go func() {
		defer trace.StartRegion(context.Background(), "Pipe.Reduce").End()
		defer close(ret.output)
		defer copyError(pipe, ret)
		var acc O = initial
		var err error
		for i := range pipe.output {
			acc, err = f(acc, i)
			if err != nil {
				ret.err = err
				return
			}

		}
		ret.output <- acc
	}()
	return
}

func Chunk[I any](pipe *Pipe[I], n int) (ret *Pipe[[]I]) {
	ret = newPipe[I, []I](pipe)
	if ret.err != nil {
		return
	}
	go func() {
		defer trace.StartRegion(context.Background(), "Pipe.Chunk").End()
		defer close(ret.output)
		defer copyError(pipe, ret)
		chunk := make([]I, 0, n)
		for i := range pipe.output {
			chunk = append(chunk, i)
			if len(chunk) == n {
				ret.output <- chunk
				chunk = make([]I, 0, n)
			}
		}
		if len(chunk) > 0 {
			ret.output <- chunk
		}
	}()
	return
}

func (pipe *Pipe[O]) Buffered(n int) (ret *Pipe[O]) {
	ret = newPipe[O, O](pipe)
	if ret.err != nil {
		return
	}
	ret.output = make(chan O, n)
	go func() {
		defer trace.StartRegion(context.Background(), "Pipe.Buffered").End()
		defer close(ret.output)
		defer copyError(pipe, ret)
		for i := range pipe.output {
			ret.output <- i
		}
	}()
	return
}

func (pipe *Pipe[O]) Tee(count int) (pipes []*Pipe[O]) {
	for i := 0; i < count; i++ {
		pipes = append(pipes, newPipe[O, O](pipe))
	}

	go func() {
		defer func() {
			for _, p := range pipes {
				close(p.output)
				copyError(pipe, p)
			}
		}()
		for i := range pipe.output {
			for _, p := range pipes {
				select {
				case <-p.done:
					return
				case p.output <- i:
				}
			}
		}
	}()
	return
}

func Zip[L, R any](left *Pipe[L], right *Pipe[R]) (ret *Pipe[struct {
	left  L
	right R
}]) {
	done := make(chan struct{})
	go func() {
		select {
		case <-left.done:
			close(done)
		case <-right.done:
			close(done)
		}
	}()
	if left.err != nil {
		return &Pipe[struct {
			left  L
			right R
		}]{nil, left.err, done}
	}
	if right.err != nil {
		return &Pipe[struct {
			left  L
			right R
		}]{nil, right.err, done}
	}
	output := make(chan struct {
		left  L
		right R
	})
	ret = &Pipe[struct {
		left  L
		right R
	}]{output, nil, done}

	go func() {
		defer close(ret.output)
		defer copyError(left, ret)
		defer copyError(right, ret)
		for {
			select {
			case <-ret.done:
				return
			case l, ok := <-left.output:
				if !ok {
					return
				}
				r, ok := <-right.output
				if !ok {
					return
				}
				ret.output <- struct {
					left  L
					right R
				}{l, r}
			}
		}
	}()
	return
}

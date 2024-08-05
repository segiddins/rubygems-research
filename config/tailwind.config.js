const defaultTheme = require("tailwindcss/defaultTheme");

/** @type {import('tailwindcss').Config} */
module.exports = {
  // mode: "jit",
  content: [
    "./app/views/**/*.rb",
    "./app/components/**/*rb",
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim,rb}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
      },
      colors: {
        "rubygems-red": "#e74c3c",
        blackish: "#141c22",
        grayish: "#c1c4ca",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
    require("@tailwindcss/aspect-ratio"),
  ],
};

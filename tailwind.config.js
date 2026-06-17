/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#e6f1fb', 100: '#b5d4f4', 200: '#85b7eb',
          400: '#378add', 600: '#185fa5', 700: '#1a5494',
          800: '#0c447c', 900: '#042c53',
        },
      },
      fontFamily: { sans: ['Inter', 'system-ui', 'sans-serif'] },
    },
  },
  plugins: [],
}

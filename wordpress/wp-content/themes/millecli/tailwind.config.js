/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './**/*.php',  // すべてのPHPファイル
    './js/**/*.js', // すべてのJSファイル
    './src/**/*.js',
    './src/**/*.jsx',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
  // クラスが動的に生成される場合に備えてsafelistを設定
  safelist: [
    // 以下は例です。必要に応じて追加/削除してください
    'bg-blue-500',
    'text-white',
    'hover:bg-blue-700',
    'font-bold',
    'py-2',
    'px-4',
    'rounded',
  ]
}

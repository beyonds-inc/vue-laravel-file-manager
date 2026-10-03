import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [vue()],
    build: {
        minify: true,
        cssCodeSplit: false,
        rollupOptions: {
            output: {
                manualChunks: {
                    vendor: [],
                },
            },
        },
    },

    css: { preprocessorOptions: { scss: { charset: false } } },

    // ePortal は file-manager.js を module ではない普通の <script> で読み込むため、import.meta を残すと読み込めない。
    // pdf.js（eportal-saas #824）は Node.js で動くときだけ import.meta.url を使うので、ブラウザでは使わない値に置き換える
    define: {
        'import.meta.url': JSON.stringify(''),
    },
});

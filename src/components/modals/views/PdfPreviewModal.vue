<template>
    <div class="modal-content fm-modal-pdf-preview">
        <div class="modal-header">
            <h5 class="modal-title w-75 text-truncate">
                {{ lang.modal.pdfPreview.title }}
                <small class="text-muted ps-3">{{ selectedItem.basename }}</small>
            </h5>
            <button type="button" class="btn-close" aria-label="Close" v-on:click="hideModal"></button>
        </div>
        <div class="modal-body p-0">
            <iframe :src="pdfUrl" allowfullscreen></iframe>
        </div>
    </div>
</template>

<script>
import modal from '../mixins/modal';
import translate from '../../../mixins/translate';

export default {
    name: 'PdfPreviewModal',
    mixins: [modal, translate],
    computed: {
        /**
         * Selected file
         * @returns {*}
         */
        selectedItem() {
            return this.$store.getters['fm/selectedItems'][0];
        },

        /**
         * Object URL of the PDF blob created by the openPDF action
         * @returns {*}
         */
        pdfUrl() {
            return this.$store.state.fm.modal.pdfPreviewUrl;
        },
    },
};
</script>

<style lang="scss">
.fm-modal-pdf-preview {
    .modal-body {
        height: 75vh;

        iframe {
            width: 100%;
            height: 100%;
            border: 0;
        }
    }
}
</style>

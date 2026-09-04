export default {
    /**
     * Modal window state
     * @param state
     * @param show
     * @param modalName
     */
    setModalState(state, { show, modalName }) {
        state.showModal = show;
        state.modalName = modalName;
    },

    /**
     * Clear modal
     * @param state
     */
    clearModal(state) {
        state.showModal = false;
        state.modalName = null;

        // release the blob to avoid leaking object URLs across previews
        if (state.pdfPreviewUrl) {
            URL.revokeObjectURL(state.pdfPreviewUrl);
            state.pdfPreviewUrl = null;
        }
    },

    /**
     * Main modal block - set height
     * @param state
     * @param height
     */
    setModalBlockHeight(state, height) {
        state.modalBlockHeight = height;
    },

    /**
     * PDF preview - set object URL
     * @param state
     * @param url
     */
    setPdfPreviewUrl(state, url) {
        state.pdfPreviewUrl = url;
    },
};

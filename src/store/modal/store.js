import mutations from './mutations';

export default {
    namespaced: true,
    state() {
        return {
            // modal window
            showModal: false,

            // modal name
            modalName: null,

            // main modal block height
            modalBlockHeight: 0,

            // object URL of the PDF blob shown in PdfPreviewModal
            pdfPreviewUrl: null,

            // file shown in CsvPreviewModal ({ disk, path, basename }). The double-clicked file,
            // not the first selected item (they differ when several files are selected)
            csvPreviewTarget: null,
        };
    },
    mutations,
};

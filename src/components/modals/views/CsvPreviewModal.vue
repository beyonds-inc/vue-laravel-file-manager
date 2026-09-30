<template>
    <div class="modal-content fm-modal-csv-preview">
        <div class="modal-header">
            <h5 class="modal-title w-75 text-truncate">
                {{ lang.modal.csvPreview.title }}
                <small class="text-muted ps-3">{{ selectedItem.basename }}</small>
            </h5>
            <button type="button" class="btn-close" aria-label="Close" v-on:click="hideModal"></button>
        </div>
        <div class="modal-body">
            <div v-if="truncated" class="alert alert-warning py-2" role="alert">
                {{ truncatedMessage }}
            </div>
            <div v-if="!encodingDetected" class="alert alert-warning py-2" role="alert">
                {{ lang.modal.csvPreview.encodingGuessed }}
            </div>
            <p v-if="loaded && rows.length === 0" class="text-muted mb-0">{{ lang.modal.csvPreview.empty }}</p>
            <div v-if="rows.length > 0" class="fm-csv-table">
                <table class="table table-sm table-bordered mb-0">
                    <thead>
                        <tr>
                            <th v-for="(cell, index) in headerRow" v-bind:key="index">{{ cell }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="(row, rowIndex) in bodyRows" v-bind:key="rowIndex">
                            <td v-for="(cell, cellIndex) in row" v-bind:key="cellIndex">{{ cell }}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</template>

<script>
import modal from '../mixins/modal';
import translate from '../../../mixins/translate';
import GET from '../../../http/get';

export default {
    name: 'CsvPreviewModal',
    mixins: [modal, translate],
    data() {
        return {
            rows: [],
            truncated: false,
            encodingDetected: true,
            loaded: false,
        };
    },
    computed: {
        /**
         * Selected disk
         * @returns {*}
         */
        selectedDisk() {
            return this.$store.getters['fm/selectedDisk'];
        },

        /**
         * Selected file
         * @returns {*}
         */
        selectedItem() {
            return this.$store.getters['fm/selectedItems'][0];
        },

        /**
         * Number of columns of the widest row (rows can have different lengths)
         * @returns {number}
         */
        columnCount() {
            return this.rows.reduce((max, row) => Math.max(max, row.length), 0);
        },

        /**
         * First row is shown as the header
         * @returns {string[]}
         */
        headerRow() {
            return this.fillRow(this.rows[0] || []);
        },

        /**
         * @returns {string[][]}
         */
        bodyRows() {
            return this.rows.slice(1).map((row) => this.fillRow(row));
        },

        /**
         * @returns {string}
         */
        truncatedMessage() {
            return this.lang.modal.csvPreview.truncated.replace('{count}', this.rows.length);
        },
    },
    mounted() {
        GET.csvPreview(this.selectedDisk, this.selectedItem.path)
            .then((response) => {
                this.rows = Array.isArray(response.data.rows) ? response.data.rows : [];
                this.truncated = response.data.truncated === true;
                this.encodingDetected = response.data.encoding_detected !== false;
                this.loaded = true;
            })
            // 表示できない理由は response interceptor が通知するので、空のモーダルは閉じる
            .catch(() => this.hideModal());
    },
    methods: {
        /**
         * Make every row as wide as the widest row. Cells are shown as text (never as HTML).
         * @param row
         * @returns {string[]}
         */
        fillRow(row) {
            const cells = row.map((cell) => (cell === null || cell === undefined ? '' : String(cell)));

            while (cells.length < this.columnCount) {
                cells.push('');
            }

            return cells;
        },
    },
};
</script>

<style lang="scss">
.fm-modal-csv-preview {
    .fm-csv-table {
        max-height: 70vh;
        overflow: auto;

        th {
            position: sticky;
            top: 0;
            background-color: var(--bs-light, #f8f9fa);
        }

        th,
        td {
            white-space: pre-wrap;
            word-break: break-word;
        }
    }
}
</style>

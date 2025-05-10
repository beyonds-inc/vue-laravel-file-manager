<template>
    <div class="modal-content fm-modal-versions">
        <div class="modal-header">
            <h5 class="modal-title">{{ lang.modal.versions.title }}</h5>
            <button type="button" class="btn-close" aria-label="Close" v-on:click="hideModal"></button>
        </div>
        <div class="modal-body">
            <div v-if="loading" class="text-center p-3">
                <div class="spinner-border" role="status">
                    <span class="visually-hidden">Loading...</span>
                </div>
            </div>
            <div v-else-if="error" class="alert alert-danger">
                {{ error }}
            </div>
            <div v-else-if="versions.length === 0" class="alert alert-info">
                {{ lang.modal.versions.noVersions }}
            </div>
            <div v-else class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>{{ lang.modal.versions.version }}</th>
                            <th>{{ lang.modal.versions.date }}</th>
                            <th>{{ lang.modal.versions.user }}</th>
                            <th>{{ lang.modal.versions.action }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="version in versions" :key="version.id">
                            <td>{{ version.version_number }}</td>
                            <td>{{ timestampToDate(version.timestamp) }}</td>
                            <td>{{ version.user_name ? version.user_name : '-' }}</td>
                            <td>
                                <button
                                    class="btn btn-sm btn-primary"
                                    v-on:click="downloadVersion(version.version_number)"
                                >
                                    <i class="bi bi-download"></i> {{ lang.btn.download }}
                                </button>
                            </td>
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
import helper from '../../../mixins/helper';

export default {
    name: 'VersionsModal',
    mixins: [modal, translate, helper],
    data() {
        return {
            versions: [],
            loading: true,
            error: null,
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
    },
    methods: {
        /**
         * Get file versions
         */
        getVersions() {
            this.loading = true;
            this.error = null;

            // API endpoint for getting file versions
            const apiUrl = `${window.location.origin}/${this.$store.state.fm.settings.baseUrl}/versions?disk=${encodeURIComponent(this.selectedDisk)}&path=${encodeURIComponent(this.selectedItem.path)}`;

            fetch(apiUrl)
                .then(response => {
                    if (!response.ok) {
                        throw new Error('Network response was not ok');
                    }
                    return response.json();
                })
                .then(data => {
                    if (data.result.status === 'success') {
                        this.versions = data.versions || [];
                    } else {
                        this.error = data.result.message || this.lang.modal.versions.error;
                    }
                    this.loading = false;
                })
                .catch(error => {
                    console.error('Error fetching versions:', error);
                    this.error = this.lang.modal.versions.error;
                    this.loading = false;
                });
        },

        /**
         * Download specific version
         * @param {number} versionNumber
         */
        downloadVersion(versionNumber) {
            const downloadUrl = `${window.location.origin}/${this.$store.state.fm.settings.baseUrl}/download-version?disk=${encodeURIComponent(this.selectedDisk)}&path=${encodeURIComponent(this.selectedItem.path)}&version=${versionNumber}`;

            const tempLink = document.createElement('a');
            tempLink.style.display = 'none';
            tempLink.href = downloadUrl;
            document.body.appendChild(tempLink);
            tempLink.click();
            document.body.removeChild(tempLink);
        },
    },
    mounted() {
        this.getVersions();
    },
};
</script>

<style lang="scss">
.fm-modal-versions {
    .table {
        table-layout: auto;
        th, td {
            vertical-align: middle;
            white-space: nowrap;
        }
    }
}
</style>

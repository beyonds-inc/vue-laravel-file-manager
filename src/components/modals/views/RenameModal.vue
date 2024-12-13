<template>
    <div class="modal-content fm-modal-rename">
        <div class="modal-header">
            <h5 class="modal-title">{{ lang.modal.rename.title }}</h5>
            <button type="button" class="btn-close" aria-label="Close" v-on:click="hideModal"></button>
        </div>
        <div class="modal-body">
            <div class="form-group">
                <label for="fm-input-rename">{{ lang.modal.rename.fieldName }}</label>
                <div class="flex">
                    <input
                        type="text"
                        class="form-control"
                        id="fm-input-rename"
                        v-focus
                        v-bind:class="{ 'is-invalid': checkName }"
                        v-model="filename"
                        v-on:keyup="validateName"
                    />
                    <label for="fm-input-rename" v-show="extension !== ''">.{{ extension }}</label>
                </div>
                <div class="invalid-feedback" v-show="checkName">
                    {{ lang.modal.rename.fieldFeedback }}
                    {{ directoryExist ? ` - ${lang.modal.rename.directoryExist}` : '' }}
                    {{ fileExist ? ` - ${lang.modal.rename.fileExist}` : '' }}
                </div>
            </div>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn btn-info" v-bind:disabled="submitDisable" v-on:click="rename">
                {{ lang.btn.save }}
            </button>
            <button type="button" class="btn btn-light" v-on:click="hideModal">{{ lang.btn.cancel }}</button>
        </div>
    </div>
</template>

<script>
import modal from '../mixins/modal';
import translate from '../../../mixins/translate';

export default {
    name: 'RenameModal',
    mixins: [modal, translate],
    data() {
        return {
            filename: '',
            extension: '',
            directoryExist: false,
            fileExist: false,
        };
    },
    computed: {
        /**
         * Selected item
         * @returns {*}
         */
        selectedItem() {
            return this.$store.getters[`fm/${this.activeManager}/selectedList`][0];
        },

        /**
         * Check new name
         * @returns {boolean}
         */
        checkName() {
            return this.directoryExist || this.fileExist || !this.filename;
        },

        /**
         * Submit button disable
         * @returns {*|boolean}
         */
        submitDisable() {
            return this.checkName || this.basename === this.selectedItem.basename;
        },

        /**
         * file name + extension 
         */
        basename() {
            return this.extension === '' ? this.filename : this.filename + '.' + this.extension;
        },
    },
    mounted() {
        // initiate item name
        this.filename = this.selectedItem.filename;
        this.extension = this.selectedItem.extension;
    },
    methods: {
        /**
         * Validate item name
         */
        validateName() {
            if (this.basename !== this.selectedItem.basename) {
                // if item - folder
                if (this.selectedItem.type === 'dir') {
                    // check folder name matches
                    this.directoryExist = this.$store.getters[`fm/${this.activeManager}/directoryExist`](this.basename);
                } else {
                    // check file name matches
                    this.fileExist = this.$store.getters[`fm/${this.activeManager}/fileExist`](this.basename);
                }
            }
        },

        /**
         * Rename item
         */
        rename() {
            // create new name with path
            const newName = this.selectedItem.dirname ? `${this.selectedItem.dirname}/${this.basename}` : this.basename;

            this.$store
                .dispatch('fm/rename', {
                    type: this.selectedItem.type,
                    newName,
                    oldName: this.selectedItem.path,
                })
                .then(() => {
                    // close modal window
                    this.hideModal();
                });
        },
    },
};
</script>
<style scoped>
.flex {
    display: flex;
    align-items: baseline;
}
</style>

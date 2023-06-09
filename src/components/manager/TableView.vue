<template>
    <div class="fm-table">
        <table class="table table-sm">
            <thead>
                <tr>
                    <th class="w-30" v-on:click="sortBy('name')">
                        {{ lang.manager.table.name }}
                        <template v-if="sortSettings.field === 'name'">
                            <i class="bi bi-sort-down" v-show="sortSettings.direction === 'down'" />
                            <i class="bi bi-sort-up" v-show="sortSettings.direction === 'up'" />
                        </template>
                    </th>
                    <th class="w-35">
                        {{ lang.manager.table.description }}
                    </th>
                    <th class="w-10" v-on:click="sortBy('size')">
                        {{ lang.manager.table.size }}
                        <template v-if="sortSettings.field === 'size'">
                            <i class="bi bi-sort-down" v-show="sortSettings.direction === 'down'" />
                            <i class="bi bi-sort-up" v-show="sortSettings.direction === 'up'" />
                        </template>
                    </th>
                    <th class="w-10" v-on:click="sortBy('type')">
                        {{ lang.manager.table.type }}
                        <template v-if="sortSettings.field === 'type'">
                            <i class="bi bi-sort-down" v-show="sortSettings.direction === 'down'" />
                            <i class="bi bi-sort-up" v-show="sortSettings.direction === 'up'" />
                        </template>
                    </th>
                    <th class="w-auto" v-on:click="sortBy('date')">
                        {{ lang.manager.table.date }}
                        <template v-if="sortSettings.field === 'date'">
                            <i class="bi bi-sort-down" v-show="sortSettings.direction === 'down'" />
                            <i class="bi bi-sort-up" v-show="sortSettings.direction === 'up'" />
                        </template>
                    </th>
                </tr>
            </thead>
            <tbody>
                <tr v-if="!isRootPath">
                    <td colspan="4" class="fm-content-item" v-on:click="levelUp">
                        <i class="bi bi-arrow-90deg-up" />
                    </td>
                </tr>
                <tr
                    v-for="(directory, index) in directories"
                    v-bind:key="`d-${index}`"
                    v-bind:class="{ 'table-info': checkSelect('directories', directory.path) }"
                    v-on:click="selectItem('directories', directory.path, $event)"
                    v-on:contextmenu.prevent="contextMenu(directory, $event)"
                >
                    <td
                        class="fm-content-item unselectable"
                        v-bind:class="acl && directory.acl === 0 ? 'text-hidden' : ''"
                        v-on:dblclick="selectDirectory(directory.path)"
                    >
                        <i class="bi bi-folder"></i> {{ directory.basename }}
                    </td>
                    <td />
                    <td />
                    <td>{{ lang.manager.table.folder }}</td>
                    <td>
                        {{ timestampToDate(directory.timestamp) }}
                    </td>
                </tr>
                <tr
                    v-for="(file, index) in files"
                    v-bind:key="`f-${index}`"
                    v-bind:class="{ 'table-info': checkSelect('files', file.path) }"
                    v-on:click="selectItem('files', file.path, $event)"
                    v-on:dblclick="selectAction(file.path, file.extension)"
                    v-on:contextmenu.prevent="contextMenu(file, $event)"
                    style="position: relative;"
                >
                    <td class="fm-content-item unselectable" v-bind:class="acl && file.acl === 0 ? 'text-hidden' : ''" @mouseleave="hidePopup();">
                        <i class="bi" v-bind:class="extensionToIcon(file.extension)" @mouseenter="showImagePopup(index); setImgSrc(file);" />
                        {{ file.filename ? abbriviatedString(file.filename, 15) : abbriviatedString(file.basename, 15) }}
                        <span v-if="isFileNew(file.timestamp)" class="new-indicator">NEW</span>
                        <div class="image-popup-wrapper">
                            <Transition>
                                <div v-if="!hasClosed && showImageFlag && showIndex === index && imageExtensions.includes(file.extension)" class="image-popup" :style="{ marginTop: '-' + windowTop + 'px' }">
                                    <button type="button" class="btn-close" aria-label="Close" @click="closePopup()" />
                                    <img :src="imgSrc" />
                                </div>
                            </Transition>
                        </div>
                    </td>
                    <td class="description" @mouseenter="showDescriptionPopup(index)" @mouseleave="hidePopup()">
                        <p>{{ abbriviatedString(file.description, 20) }}</p>
                        <div class="description-popup-wrapper">
                            <Transition>
                                <div v-if="!hasClosed && showDescriptionFlag && showIndex === index && file.description.length > 0" class="description-popup" :style="{ marginTop: '-' + windowTop + 'px' }">
                                    <button type="button" class="btn-close" aria-label="Close" @click="closePopup()" />
                                    <p class="description-popup-text">{{ file.description }}</p>
                                </div>
                            </Transition>
                        </div>
                    </td>
                    <td>{{ bytesToHuman(file.size) }}</td>
                    <td>
                        {{ file.extension }}
                    </td>
                    <td>
                        {{ timestampToDate(file.timestamp) }}
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>

<script>
import translate from '../../mixins/translate';
import helper from '../../mixins/helper';
import managerHelper from './mixins/manager';

export default {
    name: 'table-view',
    mixins: [translate, helper, managerHelper],
    props: {
        manager: { type: String, required: true },
    },
    data() {
        return {
            showDescriptionFlag: false,
            showImageFlag: false,
            hasClosed: false,
            showIndex: null,
            windowTop: null,
            imgSrc: null,
            timeout: null,
        };
    },
    computed: {
        /**
         * Sort settings
         * @returns {*}
         */
        sortSettings() {
            return this.$store.state.fm[this.manager].sort;
        },
        imageExtensions() {
            return this.$store.state.fm.settings.imageExtensions;
        },
        selectedDisk() {
            return this.$store.getters['fm/selectedDisk'];
        },
    },
    methods: {
        /**
         * 現在hoverしているファイルのsourceを取得する。
         * @param file
         */
        setImgSrc(file) {
            this.imgSrc = `${this.$store.getters['fm/settings/baseUrl']}preview?disk=${this.selectedDisk}&path=${encodeURIComponent(file.path)}&v=${file.timestamp}`;
        },
        /**
         * Sort by field
         * @param field
         */
        sortBy(field) {
            this.$store.dispatch(`fm/${this.manager}/sortBy`, { field, direction: null });
        },

        /**
         * ファイル説明が長い場合、省略形で表示する。
         * @param {string} string
         * @param {number} str_length
         * @returns {string}
         */
        abbriviatedString(string, str_length) {
            if (!string) return string;
            return string.length > str_length ? string.substring(0, str_length) + "..." : string;
        },

        /**
         * ファイル説明全文を表示する。
         * @param {number} index
         */
        showDescriptionPopup(index) {
            this.showIndex = index;
            this.timeout = setTimeout(() => {
                if (this.showIndex === index) {
                    this.showDescriptionFlag = true;
                }
            }, 1000);
        },

        /**
         * 画像のプレビューを表示する。
         * @param {number} index
         */
        showImagePopup(index) {
            this.showIndex = index;
            this.timeout = setTimeout(() => {
                if (this.showIndex === index) {
                    this.showImageFlag = true;
                }
            }, 1000);
        },

        /**
         * Popupを隠す。
         * 
         */
        hidePopup() {
            clearTimeout(this.timeout);
            this.showDescriptionFlag = false;
            this.showImageFlag = false;
            this.showIndex = null;
            this.hasClosed = false;
        },

        /**
         * Popupを閉じる。
         * 
         */
        closePopup() {
            this.hasClosed = true;
        },

        /** 当該ファイルが新しいファイルかチェック*/
        isFileNew(updatedAt) {
            const currentDate = Math.round(+new Date() / 1000);
            const elapsedDay = (currentDate - updatedAt) / 86400;
            const displayedDay = 14;
            return displayedDay > elapsedDay;
        },

        onScroll(e) {
            this.windowTop = window.top.scrollY
        },
    },
    mounted() {
        window.addEventListener("scroll", this.onScroll)
    },
    beforeDestroy() {
        window.removeEventListener("scroll", this.onScroll)
    },
};
</script>

<style lang="scss">
.fm-table {
    thead th {
        background: white;
        position: sticky;
        top: 0;
        z-index: 10;
        cursor: pointer;
        border-top: none;

        &:hover {
            background-color: #f8f9fa;
        }

        & > i {
            padding-left: 0.5rem;
        }
    }

    td {
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    tr:hover {
        background-color: #f8f9fa;
    }

    .w-10 {
        width: 10%;
    }

    .w-30 {
        width: 30%;
    }
    
    .w-35 {
        width: 35%;
    }
    
    .w-65 {
        width: 65%;
    }

    .fm-content-item {
        cursor: pointer;
        max-width: 1px;
    }

    .text-hidden {
        color: #cdcdcd;
    }

    .description {
        position: relative;
    }

    .description-popup-wrapper, .image-popup-wrapper {
        width: 400px;
        position: absolute;
        top: 0;
        left: 0;
    }

    .image-popup-wrapper img {
        max-width: 100%;
        max-height: 400px;
    }

    .description-popup, .image-popup {
        position: fixed;
        background-color: #fff;
        border: 1px solid #ccc;
        width: 400px;
        padding: 10px;
        white-space: pre-wrap;
        z-index: 10000;
    }

    .description-popup-text {
        margin-top: 12px;
    }

    .new-indicator {
        color: #fff;
        background-color: #ff0000;
        padding: 0 5px;
        border-radius: 5px;
        font-size: 12px;
    }

    .v-enter-active,
    .v-leave-active {
        transition: opacity 0.3s ease;
    }

    .v-enter-from,
    .v-leave-to {
        opacity: 0;
    }
}
</style>

<template>
    <div class="fm-table">
        <table class="table table-sm">
            <thead>
                <tr>
                    <th class="table-name w-40" v-on:click="sortBy('name')">
                        {{ lang.manager.table.name }}
                        <template v-if="sortSettings.field === 'name'">
                            <i class="bi bi-sort-down" v-show="sortSettings.direction === 'down'" />
                            <i class="bi bi-sort-up" v-show="sortSettings.direction === 'up'" />
                        </template>
                    </th>
                    <th class="table-description w-20">
                        {{ lang.manager.table.description }}
                    </th>
                    <th class="table-size w-10" v-on:click="sortBy('size')">
                        {{ lang.manager.table.size }}
                        <template v-if="sortSettings.field === 'size'">
                            <i class="bi bi-sort-down" v-show="sortSettings.direction === 'down'" />
                            <i class="bi bi-sort-up" v-show="sortSettings.direction === 'up'" />
                        </template>
                    </th>
                    <th class="table-type w-10" v-on:click="sortBy('type')">
                        {{ lang.manager.table.type }}
                        <template v-if="sortSettings.field === 'type'">
                            <i class="bi bi-sort-down" v-show="sortSettings.direction === 'down'" />
                            <i class="bi bi-sort-up" v-show="sortSettings.direction === 'up'" />
                        </template>
                    </th>
                    <th class="table-date w-auto" v-on:click="sortBy('date')">
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
                    v-on:touchstart="selectItem('directories', directory.path, $event)"
                    v-on:contextmenu.prevent="contextMenu(directory, $event)"
                >
                    <td
                        class="fm-content-item unselectable"
                        v-bind:class="acl && directory.acl === 0 ? 'text-hidden' : ''"
                        v-on:dblclick="selectDirectory(directory.path)"
                        v-on:touchend="selectDirectory(directory.path)"
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
                    v-on:touchstart="selectItem('files', file.path, $event)"
                    v-on:dblclick="selectAction(file.path, file.extension)"
                    v-on:contextmenu.prevent="contextMenu(file, $event)"
                    style="position: relative;"
                >
                    <td
                        class="fm-content-item unselectable"
                        v-bind:class="acl && file.acl === 0 ? 'text-hidden' : ''"
                        v-on:mouseleave="hidePopup()"
                        v-on:touchend="selectAction(file.path, file.extension)"
                    >
                        <i class="bi icon" v-bind:class="extensionToIcon(file.extension)" @mouseenter="showImagePopup(index); setImgSrc(file);" />
                        <span class="filename" @mouseenter="showTitlePopup(index)" >{{ file.filename ?? file.basename }}</span>
                        <span v-if="isFileNew(file.timestamp)" class="new-indicator">NEW</span>
                        <div class="image-popup-wrapper">
                            <Transition>
                                <div v-if="!hasClosed && showImageFlag && showIndex === index && imageExtensions.includes(file.extension)" class="image-popup" :style="{ marginTop: '-' + windowTop + 'px' }">
                                    <button type="button" class="btn-close" aria-label="Close" @click="closePopup()" />
                                    <img :src="imgSrc" />
                                </div>
                            </Transition>
                        </div>
                        <div class="title-popup-wrapper">
                            <Transition>
                                <div v-if="!hasClosed && showTitleFlag && showIndex === index && !showImageFlag" class="title-popup" :style="{ marginTop: '-' + windowTop + 'px' }">
                                    <button type="button" class="btn-close" aria-label="Close" @click="closePopup()" />
                                    <h3 class="title-popup-basename">{{ file.basename }}</h3>
                                    <p class="title-popup-description">{{ file.description }}</p>
                                </div>
                            </Transition>
                        </div>
                    </td>
                    <td class="description" @mouseenter="showDescriptionPopup(index)" @mouseleave="hidePopup()">
                        <span>{{ file.description }}</span>
                        <div class="description-popup-wrapper">
                            <Transition>
                                <div v-if="!hasClosed && showDescriptionFlag && showIndex === index && file.description.length > 0" class="description-popup" :style="{ marginTop: '-' + windowTop + 'px' }">
                                    <button type="button" class="btn-close" aria-label="Close" @click="closePopup()" />
                                    <h3 class="description-popup-basename">{{ file.basename }}</h3>
                                    <p class="description-popup-description">{{ file.description }}</p>
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
            showTitleFlag: false,
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
         * 説明欄にカーソルを当てた時、ファイルのフルネーム、説明全文を表示する。
         * @param {number} index
         */
        showTitlePopup(index) {
            clearTimeout(this.timeout);
            this.showIndex = index;
            this.timeout = setTimeout(() => {
                if (this.showIndex === index) {
                    this.showTitleFlag = true;
                }
            }, 500);
        },

        /**
         * 説明欄にカーソルを当てた時、ファイルのフルネーム、説明全文を表示する。
         * @param {number} index
         */
        showDescriptionPopup(index) {
            clearTimeout(this.timeout);
            this.showIndex = index;
            this.timeout = setTimeout(() => {
                if (this.showIndex === index) {
                    this.showDescriptionFlag = true;
                }
            }, 500);
        },

        /**
         * 画像のプレビューを表示する。
         * @param {number} index
         */
        showImagePopup(index) {
            clearTimeout(this.timeout);
            this.showIndex = index;
            this.timeout = setTimeout(() => {
                if (this.showIndex === index) {
                    this.showImageFlag = true;
                }
            }, 500);
        },

        /**
         * Popupを隠す。
         * 
         */
        hidePopup() {
            clearTimeout(this.timeout);
            this.showTitleFlag = false;
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
@media (min-width: 768px) {
    table {
        table-layout: fixed;
    }
}
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

    .w-20 {
        width: 20%;
    }

    .w-30 {
        width: 30%;
    }
    
    .w-35 {
        width: 35%;
    }
    
    .w-40 {
        width: 40%;
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
        max-width: 200px;
        position: relative;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .btn-close {
        display: block;
        margin-bottom: 8px;
    }

    .icon {
        display: inline-block;
    }

    .filename {
        margin-left: 0.125em;
    }
    
    .title-popup-wrapper, .description-popup-wrapper, .image-popup-wrapper {
        width: 400px;
        position: absolute;
        top: 0;
        left: 0;
    }

    .image-popup-wrapper img {
        max-width: 100%;
        max-height: 400px;
    }

    .title-popup, .description-popup, .image-popup {
        position: fixed;
        background-color: #fff;
        border: 1px solid #ccc;
        width: 400px;
        padding: 10px;
        white-space: pre-wrap;
        z-index: 10000;
    }

    .title-popup-basename, .description-popup-basename {
        font-weight: bold;
        font-size: 18px;
        margin-top: 12px;
    }

    .title-popup-description, .description-popup-description {
        margin-top: 12px;
    }

    .new-indicator {
        color: #fff;
        background-color: #ff0000;
        padding: 0 5px;
        border-radius: 5px;
        font-size: 12px;
        margin-left: 5px;
    }

    .v-enter-active,
    .v-leave-active {
        transition: opacity 0.3s ease;
    }

    .v-enter-from,
    .v-leave-to {
        opacity: 0;
    }
    .table-name {
        min-width: 150px;
    }
    .table-description {
        min-width: 150px;
    }
    .table-size {
        min-width: 70px;
    }
    .table-type {
        min-width: 80px;
    }
}
</style>

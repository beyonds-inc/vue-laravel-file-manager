import HTTP from '../../../http/get';
import EventBus from '../../../emitter';
/**
 * Context menu actions
 * {name}Action
 */

// ファイルのアクセスリンクを取得するAPIエンドポイント
const GET_MATERIAL_LINK_ENDPOINT = '/api/materials/get-material-link';

export default {
    methods: {
        /**
         * Open folder
         */
        openAction() {
            // select directory
            this.$store.dispatch(`fm/${this.$store.state.fm.activeManager}/selectDirectory`, {
                path: this.selectedItems[0].path,
                history: true,
            });
        },

        /**
         * Play music or video
         */
        audioPlayAction() {
            // show player modal
            this.$store.commit('fm/modal/setModalState', {
                modalName: 'AudioPlayerModal',
                show: true,
            });
        },

        /**
         * Play music or video
         */
        videoPlayAction() {
            // show player modal
            this.$store.commit('fm/modal/setModalState', {
                modalName: 'VideoPlayerModal',
                show: true,
            });
        },

        /**
         * View file
         */
        viewAction() {
            // show image
            this.$store.commit('fm/modal/setModalState', {
                modalName: 'PreviewModal',
                show: true,
            });
        },

        /**
         * Edit file
         */
        editAction() {
            // show text file
            this.$store.commit('fm/modal/setModalState', {
                modalName: 'TextEditModal',
                show: true,
            });
        },

        /**
         * Select file
         */
        selectAction() {
            // file callback
            this.$store
                .dispatch('fm/url', {
                    disk: this.selectedDisk,
                    path: this.selectedItems[0].path,
                })
                .then((response) => {
                    if (response.data.result.status === 'success') {
                        this.$store.state.fm.fileCallback(response.data.url);
                    }
                });
        },

        /**
         * Download file
         */
        downloadAction() {
            this.selectedItems.forEach(selectedItem => {
                const tempLink = document.createElement('a');
                tempLink.style.display = 'none';
                tempLink.setAttribute('download', selectedItem.basename);
    
                // download file with authorization
                if (this.$store.getters['fm/settings/authHeader']) {
                    HTTP.download(this.selectedDisk, selectedItem.path).then((response) => {
                        tempLink.href = window.URL.createObjectURL(new Blob([response.data]));
                        document.body.appendChild(tempLink);
                        tempLink.click();
                        document.body.removeChild(tempLink);
                    });
                } else {
                    tempLink.href = `${this.$store.getters['fm/settings/baseUrl']}download?disk=${
                        this.selectedDisk
                    }&path=${encodeURIComponent(selectedItem.path)}`;
                    document.body.appendChild(tempLink);
                    tempLink.click();
                    document.body.removeChild(tempLink);
                }
            });
        },

        /**
         * 選択したファイルのURLをクリップボードにコピー
         * DBに該当ファイルのデータが存在しない場合はコピー不可。
         * 
         */
        async copyUrlAction() {
            // URLコピーするファイルのディスク、パス
            const data = {
                disk: this.selectedDisk,
                path: this.selectedItems[0].path,
            }

            try {
                // バックエンドAPIからのレスポンス
                const response = await this.fetchMaterialLink(data);
    
                // レスポンスに応じて通知を表示
                if (response.status === 'success') {
                    navigator.clipboard.writeText(response.link);
                    EventBus.emit('addNotification', {
                        status: 'success',
                        message: this.lang.notifications.copyUrl,
                    });
                }
                // DBでファイルが見つからなかった場合
                else if (response.status === 'material_not_found') {
                    EventBus.emit('addNotification', {
                        status: 'error',
                        message: this.lang.response.fileNotFound,
                    });
                }
                // その他のエラー
                else {
                    EventBus.emit('addNotification', {
                        status: 'error',
                        message: 'URLコピーに失敗しました！',
                    });
                }
            } catch (error) {
                console.error(error);
                EventBus.emit('addNotification', {
                    status: 'error',
                    message: 'URLコピーに失敗しました！',
                });
            }
        },

        /**
         * バックエンドAPIからファイルのアクセスリンクを取得
         * 
         */
        async fetchMaterialLink(data) {
            // ファイルのアクセスリンクを取得するAPIエンドポイント
            const api_url = window.location.origin + GET_MATERIAL_LINK_ENDPOINT;

            // APIエンドポイントにリクエストを送信
            try {
                const response = await fetch(api_url, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(data),
                });
        
                if (!response.ok) {
                    throw new Error('HTTP status ' + response.status);
                }
        
                return await response.json();
            } catch (err) {
                console.error('Fetch error:', err);
                throw err;
            }
        },

        /**
         * Copy selected items
         */
        copyAction() {
            // add selected items to the clipboard
            this.$store.dispatch('fm/toClipboard', 'copy');
        },

        /**
         * Cut selected items
         */
        cutAction() {
            // add selected items to the clipboard
            this.$store.dispatch('fm/toClipboard', 'cut');
        },

        /**
         * Rename selected item
         */
        renameAction() {
            // show modal - rename
            this.$store.commit('fm/modal/setModalState', {
                modalName: 'RenameModal',
                show: true,
            });
        },

        /**
         * Paste copied or cut items
         */
        pasteAction() {
            // paste items in the selected folder
            this.$store.dispatch('fm/paste');
        },

        /**
         * Zip selected files
         */
        zipAction() {
            // show modal - Zip
            this.$store.commit('fm/modal/setModalState', {
                modalName: 'ZipModal',
                show: true,
            });
        },

        /**
         * Unzip selected archive
         */
        unzipAction() {
            // show modal - Unzip
            this.$store.commit('fm/modal/setModalState', {
                modalName: 'UnzipModal',
                show: true,
            });
        },

        /**
         * Delete selected items
         */
        deleteAction() {
            // show modal - delete
            this.$store.commit('fm/modal/setModalState', {
                modalName: 'DeleteModal',
                show: true,
            });
        },

        /**
         * Show properties for selected items
         */
        propertiesAction() {
            // show modal - properties
            this.$store.commit('fm/modal/setModalState', {
                modalName: 'PropertiesModal',
                show: true,
            });
        },
    },
};

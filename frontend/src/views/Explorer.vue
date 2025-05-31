<template>
  <div class="space-y-8">
    <!-- Floating Action Buttons -->
    <div class="fixed bottom-8 right-8 flex flex-col gap-4 z-40">
      <button class="btn btn-primary btn-circle shadow-lg" @click="showUploadModal = true">
        <TablerIcon name="upload" class="w-7 h-7" />
      </button>
      <button class="btn btn-primary btn-circle shadow-lg" @click="showNewFolderModal = true">
        <TablerIcon name="folder-plus" class="w-7 h-7" />
      </button>
      <button class="btn btn-info btn-circle shadow-lg" @click="showMapShareModal = true">
        <TablerIcon name="share" class="w-7 h-7" />
      </button>
    </div>

    <!-- Breadcrumb Navigation -->
    <div class="flex items-center gap-2 mb-4 text-sm">
      <button @click="navigateTo('/')" class="text-tiffany hover:underline">
        <TablerIcon name="home" class="w-5 h-5" />
      </button>
      <template v-for="(part, index) in pathParts" :key="index">
        <span class="text-gray-400">/</span>
        <button @click="navigateTo(breadcrumbPath(index))" class="text-tiffany hover:underline">
          {{ part }}
        </button>
      </template>
    </div>

    <!-- File/Folder Grid -->
    <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4">
      <div v-for="item in files" :key="item.path" class="group relative bg-white rounded-lg shadow p-4 flex flex-col items-center cursor-pointer hover:ring-2 hover:ring-tiffany"
        @dblclick="handleItemClick(item)"
        @contextmenu.prevent="openContextMenu($event, item)">
        <TablerIcon :name="item.type === 'directory' ? 'folder' : 'file'" class="w-10 h-10 mb-2 text-tiffany" />
        <div class="truncate w-full text-center">{{ item.name }}</div>
        <button class="absolute top-2 right-2 btn btn-xs btn-ghost opacity-0 group-hover:opacity-100" @click.stop="openContextMenu($event, item)">
          <TablerIcon name="dots" />
        </button>
      </div>
    </div>

    <!-- Context Menu -->
    <div v-if="contextMenu.show" :style="{ top: contextMenu.y + 'px', left: contextMenu.x + 'px' }" class="fixed z-50 bg-base-100 shadow-lg rounded-lg border border-base-200 w-40">
      <ul>
        <li><button class="w-full text-left px-4 py-2 hover:bg-tiffany/10" @click="downloadItem(contextMenu.item)"><TablerIcon name="download" class="w-4 h-4 mr-2" /> Download</button></li>
        <li><button class="w-full text-left px-4 py-2 hover:bg-tiffany/10" @click="moveItem(contextMenu.item)"><TablerIcon name="arrows-move" class="w-4 h-4 mr-2" /> Move</button></li>
        <li><button class="w-full text-left px-4 py-2 hover:bg-tiffany/10" @click="shareItem(contextMenu.item)"><TablerIcon name="share" class="w-4 h-4 mr-2" /> Share</button></li>
        <li><button class="w-full text-left px-4 py-2 hover:bg-red-100 text-red-600" @click="confirmDeleteItem(contextMenu.item)"><TablerIcon name="trash" class="w-4 h-4 mr-2" /> Delete</button></li>
      </ul>
    </div>

    <!-- Confirm Delete Modal -->
    <dialog v-if="showConfirmDelete" class="modal modal-open">
      <form method="dialog" class="modal-box" @submit.prevent="doDeleteItem">
        <h3 class="font-bold text-lg mb-4">Confirm Delete</h3>
        <p>Are you sure you want to delete <span class="font-bold">{{ itemToDelete?.name }}</span>? This action cannot be undone.</p>
        <div class="modal-action">
          <button class="btn" @click="showConfirmDelete = false" type="button">Cancel</button>
          <button class="btn btn-error" type="submit">Delete</button>
        </div>
      </form>
    </dialog>

    <!-- Upload Modal -->
    <dialog v-if="showUploadModal" class="modal modal-open">
      <form method="dialog" class="modal-box" @submit.prevent="uploadFiles">
        <h3 class="font-bold text-lg mb-4">Upload Files</h3>
        <input type="file" multiple @change="handleFileSelect" class="mb-4" />
        <div class="modal-action">
          <button class="btn" @click="showUploadModal = false" type="button">Cancel</button>
          <button class="btn btn-primary" type="submit">Upload</button>
        </div>
      </form>
    </dialog>

    <!-- New Folder Modal -->
    <dialog v-if="showNewFolderModal" class="modal modal-open">
      <form method="dialog" class="modal-box" @submit.prevent="createFolder">
        <h3 class="font-bold text-lg mb-4">New Folder</h3>
        <input v-model="newFolderName" class="input input-bordered w-full mb-4" placeholder="Folder name" required />
        <div class="modal-action">
          <button class="btn" @click="showNewFolderModal = false" type="button">Cancel</button>
          <button class="btn btn-primary" type="submit">Create</button>
        </div>
      </form>
    </dialog>

    <!-- Map Remote Share Modal -->
    <dialog v-if="showMapShareModal" class="modal modal-open">
      <form method="dialog" class="modal-box" @submit.prevent="mapShare">
        <h3 class="font-bold text-lg mb-4">Map Remote Share</h3>
        <div class="mb-2">
          <label class="label">Type</label>
          <select v-model="shareForm.type" class="select select-bordered w-full" required>
            <option value="smb">SMB (Windows Share)</option>
            <option value="scp">SCP (Linux/Unix)</option>
          </select>
        </div>
        <div class="mb-2">
          <label class="label">Remote Path</label>
          <input v-model="shareForm.path" class="input input-bordered w-full" required />
        </div>
        <div class="mb-2">
          <label class="label">Username</label>
          <input v-model="shareForm.username" class="input input-bordered w-full" />
        </div>
        <div class="mb-2">
          <label class="label">Password</label>
          <input v-model="shareForm.password" class="input input-bordered w-full" type="password" />
        </div>
        <div class="modal-action">
          <button class="btn" @click="showMapShareModal = false" type="button">Cancel</button>
          <button class="btn btn-primary" type="submit">Map Share</button>
        </div>
      </form>
    </dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import TablerIcon from '../components/TablerIcon.vue'
// import { explorerApi } from '@/services/api' // Uncomment and use real API

const files = ref([])
const currentPath = ref('/')
const showUploadModal = ref(false)
const showNewFolderModal = ref(false)
const showMapShareModal = ref(false)
const newFolderName = ref('')
const selectedFiles = ref([])
const contextMenu = ref({ show: false, x: 0, y: 0, item: null })
const shareForm = ref({ type: 'smb', path: '', username: '', password: '' })
const showConfirmDelete = ref(false)
const itemToDelete = ref(null)
const pendingDelete = ref(null)
const undoTimeout = ref(null)

const pathParts = computed(() => currentPath.value.split('/').filter(Boolean))
const breadcrumbPath = (index) => '/' + pathParts.value.slice(0, index + 1).join('/')

const fetchFiles = async () => {
  // TODO: Replace with real API call
  files.value = [
    { path: '/docs', name: 'docs', type: 'directory' },
    { path: '/music', name: 'music', type: 'directory' },
    { path: '/report.pdf', name: 'report.pdf', type: 'file' },
    { path: '/photo.jpg', name: 'photo.jpg', type: 'file' }
  ]
}

const navigateTo = (path) => {
  currentPath.value = path
  fetchFiles()
}
const handleItemClick = (item) => {
  if (item.type === 'directory') navigateTo(item.path)
}
const openContextMenu = (e, item) => {
  contextMenu.value = { show: true, x: e.clientX, y: e.clientY, item }
  document.addEventListener('click', closeContextMenu)
}
const closeContextMenu = () => {
  contextMenu.value.show = false
  document.removeEventListener('click', closeContextMenu)
}
const downloadItem = (item) => {
  window.$toast({ message: `Download ${item.name}`, type: 'info', icon: 'ti ti-download' })
  closeContextMenu()
}
const moveItem = (item) => {
  window.$toast({ message: `Move ${item.name}`, type: 'info', icon: 'ti ti-arrows-move' })
  closeContextMenu()
}
const shareItem = (item) => {
  window.$toast({ message: `Share ${item.name}`, type: 'info', icon: 'ti ti-share' })
  closeContextMenu()
}
const confirmDeleteItem = (item) => {
  itemToDelete.value = item
  showConfirmDelete.value = true
  closeContextMenu()
}
const doDeleteItem = () => {
  showConfirmDelete.value = false
  // Mark item for pending delete, but don't remove yet
  pendingDelete.value = itemToDelete.value
  window.$toast({
    message: `Deleted ${itemToDelete.value.name}`,
    type: 'info',
    icon: 'ti ti-trash',
    action: {
      label: 'Undo',
      onClick: undoDelete
    },
    duration: 5000
  })
  // Remove from UI immediately (simulate)
  files.value = files.value.filter(f => f.path !== itemToDelete.value.path)
  // Set timeout to perform actual delete after 5s
  undoTimeout.value = setTimeout(() => {
    // TODO: Call backend delete here
    pendingDelete.value = null
    undoTimeout.value = null
  }, 5000)
}
const undoDelete = () => {
  if (pendingDelete.value) {
    files.value.push(pendingDelete.value)
    pendingDelete.value = null
    if (undoTimeout.value) {
      clearTimeout(undoTimeout.value)
      undoTimeout.value = null
    }
    window.$toast({ message: 'Delete undone', type: 'success', icon: 'ti ti-arrow-back-up' })
  }
}
const handleFileSelect = (e) => {
  selectedFiles.value = Array.from(e.target.files)
}
const uploadFiles = () => {
  window.$toast({ message: 'Files uploaded', type: 'success', icon: 'ti ti-upload' })
  showUploadModal.value = false
}
const createFolder = () => {
  window.$toast({ message: `Folder '${newFolderName.value}' created`, type: 'success', icon: 'ti ti-folder-plus' })
  showNewFolderModal.value = false
}
const mapShare = () => {
  window.$toast({ message: `Mapped ${shareForm.value.type.toUpperCase()} share`, type: 'success', icon: 'ti ti-share' })
  showMapShareModal.value = false
}

onMounted(fetchFiles)
</script> 
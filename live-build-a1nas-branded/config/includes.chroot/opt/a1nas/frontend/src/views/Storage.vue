<template>
  <div class="container mx-auto p-4">
    <div class="space-y-8">
      <div class="flex flex-col md:flex-row gap-4 mb-4">
        <button class="btn btn-primary flex-1 text-lg py-6" @click="showAddPoolModal = true">
          <TablerIcon name="database-plus" class="w-6 h-6 mr-2" /> Add Pool
        </button>
        <button class="btn btn-primary flex-1 text-lg py-6" @click="addCache">
          <TablerIcon name="database-cog" class="w-6 h-6 mr-2" /> Add Cache
        </button>
        <button class="btn btn-info flex-1 text-lg py-6" @click="spinDownDisks">
          <TablerIcon name="power" class="w-6 h-6 mr-2" /> Spin Down Disks
        </button>
        <button class="btn btn-info flex-1 text-lg py-6" @click="spinUpDisks">
          <TablerIcon name="power" class="w-6 h-6 mr-2 rotate-180" /> Spin Up Disks
        </button>
      </div>
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-bold mb-4 text-tiffany">Pools & Drives</h3>
        <table class="table w-full">
          <thead>
            <tr>
              <th>Name</th>
              <th>Status</th>
              <th>Drives</th>
              <th>Health</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="pool in pools" :key="pool.name">
              <td>{{ pool.name }}</td>
              <td>
                <span :class="['badge', pool.status === 'ONLINE' ? 'badge-success' : 'badge-error']">{{ pool.status }}</span>
              </td>
              <td>
                <span v-for="d in pool.drives" :key="d" class="badge badge-info mr-1">{{ d }}</span>
              </td>
              <td>
                <span :class="['badge', pool.health === 'Healthy' ? 'badge-success' : pool.health === 'Warning' ? 'badge-warning' : 'badge-error']">{{ pool.health }}</span>
              </td>
              <td class="flex gap-2">
                <button class="btn btn-xs btn-ghost text-tiffany" @click="managePool(pool)"><TablerIcon name="settings" /></button>
                <button class="btn btn-xs btn-ghost text-red-500" @click="confirmDestroyPool(pool)"><TablerIcon name="trash" /></button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Device Info Table -->
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-bold mb-4 text-tiffany">Device Info</h3>
        <table class="table w-full">
          <thead>
            <tr>
              <th>Device</th>
              <th>Serial</th>
              <th>Size</th>
              <th>Temp (°C)</th>
              <th>Health (SMART)</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="dev in deviceInfo" :key="dev.device">
              <td>{{ dev.device }}</td>
              <td>{{ dev.serial || '-' }}</td>
              <td>{{ formatSize(dev.size) }}</td>
              <td>{{ dev.temp || '-' }}</td>
              <td>
                <span :class="['badge', dev.health === 'Healthy' ? 'badge-success' : dev.health === 'Failed' ? 'badge-error' : 'badge-warning']">{{ dev.health }}</span>
              </td>
              <td>
                <button class="btn btn-xs btn-ghost text-tiffany" @click="blinkDrive(dev.device)"><TablerIcon name="bulb" /></button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- File Explorer -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 mt-4">
        <div class="bg-white rounded-lg shadow p-4">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-xl font-bold">File Explorer</h2>
            <div class="flex gap-2">
              <button @click="refreshFiles"
                class="px-3 py-1 text-blue-600 hover:text-blue-800">
                <i class="fas fa-sync-alt"></i>
              </button>
              <button @click="showUploadModal = true"
                class="px-3 py-1 text-green-600 hover:text-green-800">
                <i class="fas fa-upload"></i>
              </button>
              <button @click="createNewDirectory"
                class="px-3 py-1 text-blue-600 hover:text-blue-800">
                <i class="fas fa-folder-plus"></i>
              </button>
            </div>
          </div>

          <!-- Breadcrumb Navigation -->
          <div class="flex items-center gap-2 mb-4 text-sm">
            <button @click="navigateTo('/')" class="text-blue-600 hover:text-blue-800">
              <i class="fas fa-home"></i>
            </button>
            <template v-for="(part, index) in currentPath.split('/').filter(Boolean)" :key="index">
              <span class="text-gray-500">/</span>
              <button @click="navigateTo('/' + currentPath.split('/').slice(0, index + 1).join('/'))"
                class="text-blue-600 hover:text-blue-800">
                {{ part }}
              </button>
            </template>
          </div>

          <!-- File List -->
          <div class="border rounded-lg overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Size</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Modified</th>
                  <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <tr v-for="file in files" :key="file.path" class="hover:bg-gray-50">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <button @click="handleFileClick(file)"
                      class="flex items-center text-blue-600 hover:text-blue-800">
                      <i :class="file.type === 'directory' ? 'fas fa-folder' : 'fas fa-file'" class="mr-2"></i>
                      {{ file.name }}
                    </button>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {{ file.type === 'directory' ? '-' : formatFileSize(file.size) }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {{ formatDate(file.modified) }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <div class="flex justify-end gap-2">
                      <button v-if="file.type !== 'directory'" @click="downloadFile(file)"
                        class="text-blue-600 hover:text-blue-800">
                        <i class="fas fa-download"></i>
                      </button>
                      <button @click="confirmDelete(file)"
                        class="text-red-600 hover:text-red-800">
                        <i class="fas fa-trash"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Upload Modal -->
      <div v-if="showUploadModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
        <div class="bg-white rounded-lg p-6 w-full max-w-md">
          <h3 class="text-lg font-semibold mb-4">Upload Files</h3>
          <input type="file" multiple @change="handleFileSelect" class="mb-4">
          <div class="flex justify-end gap-2">
            <button @click="showUploadModal = false"
              class="px-4 py-2 text-gray-600 hover:text-gray-800">
              Cancel
            </button>
            <button @click="uploadFiles"
              class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
              Upload
            </button>
          </div>
        </div>
      </div>

      <!-- Add Pool Modal -->
      <dialog v-if="showAddPoolModal" class="modal modal-open">
        <form method="dialog" class="modal-box" @submit.prevent="createPool">
          <h3 class="font-bold text-lg mb-4">Create ZFS Pool</h3>
          <div class="mb-2">
            <label class="label">Pool Name</label>
            <input v-model="poolForm.name" class="input input-bordered w-full" required />
          </div>
          <div class="mb-2">
            <label class="label">RAID Type</label>
            <select v-model="poolForm.raidType" class="select select-bordered w-full" required>
              <option value="mirror">Mirror</option>
              <option value="raidz">RAID-Z</option>
              <option value="raidz2">RAID-Z2</option>
              <option value="raidz3">RAID-Z3</option>
              <option value="stripe">Stripe</option>
            </select>
          </div>
          <div class="mb-2">
            <label class="label">Devices</label>
            <div class="flex flex-wrap gap-2">
              <label v-for="dev in availableDevices" :key="dev" class="flex items-center gap-2">
                <input type="checkbox" v-model="poolForm.devices" :value="dev" class="checkbox checkbox-primary" />
                {{ dev }}
              </label>
            </div>
          </div>
          <div class="modal-action">
            <button class="btn" @click="showAddPoolModal = false" type="button">Cancel</button>
            <button class="btn btn-primary" type="submit" :disabled="creatingPool">Create</button>
          </div>
          <div v-if="creatingPool" class="mt-4 flex items-center gap-2">
            <span class="loading loading-spinner text-tiffany"></span>
            <span>Creating pool...</span>
          </div>
        </form>
      </dialog>

      <!-- Destroy Pool Modal -->
      <dialog v-if="showDestroyModal" class="modal modal-open">
        <form method="dialog" class="modal-box" @submit.prevent="destroyPool">
          <h3 class="font-bold text-lg mb-4">Destroy Pool</h3>
          <p>Are you sure you want to destroy pool <span class="font-bold text-red-500">{{ poolToDestroy?.name }}</span>? This cannot be undone.</p>
          <div class="modal-action">
            <button class="btn" @click="showDestroyModal = false" type="button">Cancel</button>
            <button class="btn btn-error" type="submit" :disabled="destroyingPool">Destroy</button>
          </div>
          <div v-if="destroyingPool" class="mt-4 flex items-center gap-2">
            <span class="loading loading-spinner text-red-500"></span>
            <span>Destroying pool...</span>
          </div>
        </form>
      </dialog>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { storageApi } from '../services/api';
import TablerIcon from '../components/TablerIcon.vue'

// ZFS Pool Management
const pools = ref([]);
const poolStatus = ref({});
const availableDevices = ref([]);
const showAddPoolModal = ref(false);
const creatingPool = ref(false);
const poolForm = ref({ name: '', raidType: 'mirror', devices: [] });
const showDestroyModal = ref(false);
const destroyingPool = ref(false);
const poolToDestroy = ref(null);
const deviceInfo = ref([]);

// File Explorer
const files = ref([]);
const currentPath = ref('/');
const showUploadModal = ref(false);
const selectedFiles = ref([]);

// Load initial data
onMounted(async () => {
  await Promise.all([
    fetchPools(),
    fetchAvailableDevices(),
    fetchFiles(),
    fetchDeviceInfo()
  ]);
});

// ZFS Pool Methods
const fetchPools = async () => {
  try {
    const res = await fetch('/api/storage/pools', { credentials: 'include' })
    const data = await res.json()
    // For each pool, fetch status/health
    pools.value = await Promise.all((data.pools || []).map(async (name, i) => {
      let status = 'UNKNOWN', health = 'Unknown', drives = []
      try {
        const sres = await fetch(`/api/storage/pools/${name}/status`, { credentials: 'include' })
        const sdata = await sres.json()
        // Parse status/health from sdata.raw or sdata.status
        status = (sdata.raw?.match(/state: (\w+)/)?.[1] || 'UNKNOWN').toUpperCase()
        health = sdata.status ? sdata.status.charAt(0).toUpperCase() + sdata.status.slice(1) : 'Unknown'
        // Optionally parse drives from sdata.raw
      } catch {}
      return { id: i, name, status, drives, health }
    }))
  } catch (e) {
    window.$toast({ message: 'Failed to fetch pools', type: 'error', icon: 'ti ti-alert-triangle' })
  }
}

const fetchDevices = async () => {
  try {
    const res = await fetch('/api/storage/devices', { credentials: 'include' })
    availableDevices.value = await res.json()
  } catch (e) {
    window.$toast({ message: 'Failed to fetch devices', type: 'error', icon: 'ti ti-alert-triangle' })
  }
}

const fetchDeviceInfo = async () => {
  try {
    const res = await fetch('/api/storage/devices/info', { credentials: 'include' })
    deviceInfo.value = await res.json()
  } catch (e) {
    window.$toast({ message: 'Failed to fetch device info', type: 'error', icon: 'ti ti-alert-triangle' })
  }
}

const addCache = () => {
  window.$toast({ message: 'Add Cache clicked', type: 'info', icon: 'ti ti-database-cog' })
}

const managePool = (pool) => {
  window.$toast({ message: `Manage ${pool.name} clicked`, type: 'info', icon: 'ti ti-settings' })
}

const createPool = async () => {
  creatingPool.value = true
  try {
    const res = await fetch('/api/storage/pools', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({
        name: poolForm.value.name,
        raidType: poolForm.value.raidType,
        devices: poolForm.value.devices
      })
    })
    if (!res.ok) throw new Error((await res.json()).error || 'Failed to create pool')
    window.$toast({ message: `Pool '${poolForm.value.name}' created`, type: 'success', icon: 'ti ti-database-plus' })
    showAddPoolModal.value = false
    poolForm.value = { name: '', raidType: 'mirror', devices: [] }
    await fetchPools()
    await fetchDeviceInfo()
  } catch (e) {
    window.$toast({ message: e.message || 'Failed to create pool', type: 'error', icon: 'ti ti-alert-triangle' })
  } finally {
    creatingPool.value = false
  }
}

const confirmDestroyPool = (pool) => {
  poolToDestroy.value = pool
  showDestroyModal.value = true
}

const destroyPool = async () => {
  destroyingPool.value = true
  try {
    const res = await fetch(`/api/storage/pools/${poolToDestroy.value.name}`, {
      method: 'DELETE',
      credentials: 'include'
    })
    if (!res.ok) throw new Error((await res.json()).error || 'Failed to destroy pool')
    window.$toast({ message: `Pool '${poolToDestroy.value.name}' destroyed`, type: 'success', icon: 'ti ti-trash' })
    showDestroyModal.value = false
    await fetchPools()
    await fetchDeviceInfo()
  } catch (e) {
    window.$toast({ message: e.message || 'Failed to destroy pool', type: 'error', icon: 'ti ti-alert-triangle' })
  } finally {
    destroyingPool.value = false
  }
}

const spinDownDisks = async () => {
  window.$toast({ message: 'Spinning down disks...', type: 'info', icon: 'ti ti-power' })
  try {
    const res = await fetch('/api/storage/spin-down', { method: 'POST', credentials: 'include' })
    if (!res.ok) throw new Error((await res.json()).error || 'Failed to spin down disks')
    window.$toast({ message: 'All disks spun down', type: 'success', icon: 'ti ti-power' })
  } catch (e) {
    window.$toast({ message: e.message || 'Failed to spin down disks', type: 'error', icon: 'ti ti-alert-triangle' })
  }
}

const spinUpDisks = async () => {
  window.$toast({ message: 'Spinning up disks...', type: 'info', icon: 'ti ti-power' })
  try {
    const res = await fetch('/api/storage/spin-up', { method: 'POST', credentials: 'include' })
    if (!res.ok) throw new Error((await res.json()).error || 'Failed to spin up disks')
    window.$toast({ message: 'All disks spun up', type: 'success', icon: 'ti ti-power' })
  } catch (e) {
    window.$toast({ message: e.message || 'Failed to spin up disks', type: 'error', icon: 'ti ti-alert-triangle' })
  }
}

// File Explorer Methods
async function fetchFiles() {
  try {
    const response = await storageApi.listFiles(currentPath.value);
    files.value = response.data;
  } catch (error) {
    console.error('Failed to fetch files:', error);
  }
}

function navigateTo(path) {
  currentPath.value = path;
  fetchFiles();
}

function handleFileClick(file) {
  if (file.type === 'directory') {
    navigateTo(file.path);
  }
}

async function downloadFile(file) {
  try {
    const response = await storageApi.downloadFile(file.path);
    const url = window.URL.createObjectURL(new Blob([response.data]));
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', file.name);
    document.body.appendChild(link);
    link.click();
    link.remove();
  } catch (error) {
    console.error('Failed to download file:', error);
  }
}

async function confirmDelete(file) {
  if (!confirm(`Are you sure you want to delete ${file.name}?`)) return;
  try {
    await storageApi.deleteItem(file.path);
    await fetchFiles();
  } catch (error) {
    console.error('Failed to delete item:', error);
  }
}

async function createNewDirectory() {
  const name = prompt('Enter directory name:');
  if (!name) return;
  try {
    await storageApi.createDirectory(currentPath.value + '/' + name);
    await fetchFiles();
  } catch (error) {
    console.error('Failed to create directory:', error);
  }
}

function handleFileSelect(event) {
  selectedFiles.value = Array.from(event.target.files);
}

async function uploadFiles() {
  try {
    await Promise.all(selectedFiles.value.map(file =>
      storageApi.uploadFile(currentPath.value, file)
    ));
    showUploadModal.value = false;
    selectedFiles.value = [];
    await fetchFiles();
  } catch (error) {
    console.error('Failed to upload files:', error);
  }
}

function refreshFiles() {
  fetchFiles();
}

// Utility Functions
function formatFileSize(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function formatDate(date) {
  return new Date(date).toLocaleString();
}

function formatSize(bytes) {
  if (!bytes || isNaN(Number(bytes))) return '-'
  const n = Number(bytes)
  if (n < 1024) return n + ' B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB']
  const i = Math.floor(Math.log(n) / Math.log(k))
  return parseFloat((n / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const blinkDrive = async (device) => {
  window.$toast({ message: `Blinking ${device}...`, type: 'info', icon: 'ti ti-bulb' })
  try {
    const res = await fetch('/api/storage/devices/blink', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ device })
    })
    if (!res.ok) throw new Error((await res.json()).error || 'Failed to blink drive')
    window.$toast({ message: `Drive ${device} blinked`, type: 'success', icon: 'ti ti-bulb' })
  } catch (e) {
    window.$toast({ message: e.message || 'Failed to blink drive', type: 'error', icon: 'ti ti-alert-triangle' })
  }
}
</script> 
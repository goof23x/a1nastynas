<template>
  <div class="container mx-auto p-4">
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <!-- ZFS Pool Management -->
      <div class="bg-white rounded-lg shadow p-4">
        <h2 class="text-xl font-bold mb-4">ZFS Pool Management</h2>
        
        <!-- Create Pool Form -->
        <form @submit.prevent="createPool" class="mb-6">
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700">Pool Name</label>
            <input v-model="newPool.name" type="text" required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
          </div>
          
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700">RAID Type</label>
            <select v-model="newPool.raidType" required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
              <option value="mirror">Mirror</option>
              <option value="raidz">RAID-Z</option>
              <option value="raidz2">RAID-Z2</option>
              <option value="raidz3">RAID-Z3</option>
            </select>
          </div>
          
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700">Devices</label>
            <div v-for="(device, index) in newPool.devices" :key="index" class="flex gap-2 mb-2">
              <select v-model="newPool.devices[index]" required
                class="flex-1 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                <option v-for="dev in availableDevices" :key="dev" :value="dev">{{ dev }}</option>
              </select>
              <button type="button" @click="removeDevice(index)"
                class="px-3 py-2 text-red-600 hover:text-red-800">
                <i class="fas fa-times"></i>
              </button>
            </div>
            <button type="button" @click="addDevice"
              class="mt-2 text-blue-600 hover:text-blue-800">
              <i class="fas fa-plus"></i> Add Device
            </button>
          </div>
          
          <button type="submit"
            class="w-full bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
            Create Pool
          </button>
        </form>
        
        <!-- Existing Pools -->
        <div>
          <h3 class="text-lg font-semibold mb-2">Existing Pools</h3>
          <div v-for="pool in pools" :key="pool" class="flex items-center justify-between p-2 bg-gray-50 rounded mb-2">
            <div>
              <span class="font-medium">{{ pool }}</span>
              <span class="ml-2 text-sm text-gray-500">{{ poolStatus[pool]?.status || 'Unknown' }}</span>
            </div>
            <div class="flex gap-2">
              <button @click="refreshPoolStatus(pool)"
                class="px-3 py-1 text-blue-600 hover:text-blue-800">
                <i class="fas fa-sync-alt"></i>
              </button>
              <button @click="destroyPool(pool)"
                class="px-3 py-1 text-red-600 hover:text-red-800">
                <i class="fas fa-trash"></i>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- File Explorer -->
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
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { storageApi } from '../services/api';

// ZFS Pool Management
const pools = ref([]);
const poolStatus = ref({});
const availableDevices = ref([]);
const newPool = ref({
  name: '',
  raidType: 'mirror',
  devices: ['', '']
});

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
    fetchFiles()
  ]);
});

// ZFS Pool Methods
async function fetchPools() {
  try {
    const response = await storageApi.listPools();
    pools.value = response.data;
    await Promise.all(pools.value.map(pool => refreshPoolStatus(pool)));
  } catch (error) {
    console.error('Failed to fetch pools:', error);
  }
}

async function fetchAvailableDevices() {
  try {
    const response = await storageApi.getAvailableDevices();
    availableDevices.value = response.data;
  } catch (error) {
    console.error('Failed to fetch devices:', error);
  }
}

async function createPool() {
  try {
    await storageApi.createPool(newPool.value.name, newPool.value.devices, newPool.value.raidType);
    await fetchPools();
    newPool.value = { name: '', raidType: 'mirror', devices: ['', ''] };
  } catch (error) {
    console.error('Failed to create pool:', error);
  }
}

async function refreshPoolStatus(pool) {
  try {
    const response = await storageApi.getPoolStatus(pool);
    poolStatus.value[pool] = response.data;
  } catch (error) {
    console.error('Failed to refresh pool status:', error);
  }
}

async function destroyPool(pool) {
  if (!confirm(`Are you sure you want to destroy pool ${pool}?`)) return;
  try {
    await storageApi.destroyPool(pool);
    await fetchPools();
  } catch (error) {
    console.error('Failed to destroy pool:', error);
  }
}

function addDevice() {
  newPool.value.devices.push('');
}

function removeDevice(index) {
  newPool.value.devices.splice(index, 1);
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
</script> 
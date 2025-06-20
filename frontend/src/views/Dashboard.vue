<template>
  <div class="space-y-6">
    <!-- Welcome Header with Quick Actions -->
    <div class="bg-gradient-to-br from-tiffany/10 via-blue-50 to-purple-50 rounded-2xl p-8 border border-tiffany/20">
      <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between">
        <div class="mb-6 lg:mb-0">
          <h1 class="text-3xl font-bold text-gray-900 mb-2">Welcome back! 👋</h1>
          <p class="text-gray-600 text-lg">Your A1NAS is running smoothly with {{ formatFileSize(storage.available) }} free space</p>
        </div>
        <div class="flex flex-wrap gap-3">
          <button class="btn btn-primary btn-lg gap-2 hover:scale-105 transform transition-all" @click="showUploadModal = true">
            <TablerIcon name="cloud-upload" class="w-5 h-5" />
            Upload Files
          </button>
          <button class="btn btn-outline btn-lg gap-2 hover:scale-105 transform transition-all" @click="createFolder">
            <TablerIcon name="folder-plus" class="w-5 h-5" />
            New Folder
          </button>
        </div>
      </div>
    </div>

    <!-- Performance Dashboard Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <!-- Storage Usage Card -->
      <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100 hover:shadow-xl transition-all duration-300">
        <div class="flex items-center justify-between mb-4">
          <div class="p-3 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl">
            <TablerIcon name="database" class="w-6 h-6 text-white" />
          </div>
          <div class="text-right">
            <div class="text-2xl font-bold text-gray-900">{{ Math.round(storage.usedPercent) }}%</div>
            <div class="text-sm text-gray-500">Used</div>
          </div>
        </div>
        <div class="space-y-2">
          <div class="flex justify-between text-sm">
            <span class="text-gray-600">{{ formatFileSize(storage.used) }} used</span>
            <span class="text-gray-400">{{ formatFileSize(storage.total) }} total</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2">
            <div class="bg-gradient-to-r from-blue-500 to-blue-600 h-2 rounded-full transition-all duration-500" 
                 :style="{ width: storage.usedPercent + '%' }"></div>
          </div>
        </div>
      </div>

      <!-- Network Speed Card -->
      <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100 hover:shadow-xl transition-all duration-300">
        <div class="flex items-center justify-between mb-4">
          <div class="p-3 bg-gradient-to-br from-green-500 to-green-600 rounded-xl">
            <TablerIcon name="wifi" class="w-6 h-6 text-white" />
          </div>
          <div class="text-right">
            <div class="text-2xl font-bold text-gray-900">{{ network.throughput }}</div>
            <div class="text-sm text-gray-500">MB/s</div>
          </div>
        </div>
        <div class="space-y-2">
          <div class="flex justify-between text-sm">
            <span class="text-gray-600">↑ {{ network.upload }} MB/s</span>
            <span class="text-gray-600">↓ {{ network.download }} MB/s</span>
          </div>
          <div class="text-xs text-gray-500">Real-time transfer speed</div>
        </div>
      </div>

      <!-- System Health Card -->
      <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100 hover:shadow-xl transition-all duration-300">
        <div class="flex items-center justify-between mb-4">
          <div class="p-3 bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl">
            <TablerIcon name="heart" class="w-6 h-6 text-white" />
          </div>
          <div class="text-right">
            <div class="text-2xl font-bold text-green-600">Healthy</div>
            <div class="text-sm text-gray-500">All systems</div>
          </div>
        </div>
        <div class="space-y-2">
          <div class="flex justify-between text-sm">
            <span class="text-gray-600">CPU: {{ system.cpu }}%</span>
            <span class="text-gray-600">RAM: {{ system.memory }}%</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-600">Temp: {{ system.temp }}°C</span>
            <span class="text-green-600">● Online</span>
          </div>
        </div>
      </div>

      <!-- Quick Stats Card -->
      <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100 hover:shadow-xl transition-all duration-300">
        <div class="flex items-center justify-between mb-4">
          <div class="p-3 bg-gradient-to-br from-orange-500 to-orange-600 rounded-xl">
            <TablerIcon name="chart-line" class="w-6 h-6 text-white" />
          </div>
          <div class="text-right">
            <div class="text-2xl font-bold text-gray-900">{{ stats.totalFiles.toLocaleString() }}</div>
            <div class="text-sm text-gray-500">Files</div>
          </div>
        </div>
        <div class="space-y-2">
          <div class="flex justify-between text-sm">
            <span class="text-gray-600">Folders: {{ stats.folders.toLocaleString() }}</span>
            <span class="text-gray-600">Users: {{ stats.users }}</span>
          </div>
          <div class="text-xs text-gray-500">Across all shares</div>
        </div>
      </div>
    </div>

    <!-- Performance Charts Section -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Storage Performance Chart -->
      <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100">
        <div class="flex items-center justify-between mb-6">
          <h3 class="text-xl font-bold text-gray-900">Storage Performance</h3>
          <div class="flex gap-2">
            <button class="btn btn-sm btn-ghost" :class="{ 'btn-active': chartTimeframe === '1h' }" @click="chartTimeframe = '1h'">1H</button>
            <button class="btn btn-sm btn-ghost" :class="{ 'btn-active': chartTimeframe === '24h' }" @click="chartTimeframe = '24h'">24H</button>
            <button class="btn btn-sm btn-ghost" :class="{ 'btn-active': chartTimeframe === '7d' }" @click="chartTimeframe = '7d'">7D</button>
          </div>
        </div>
        <div class="h-64 flex items-center justify-center bg-gray-50 rounded-lg">
          <div class="text-center">
            <TablerIcon name="chart-area" class="w-12 h-12 text-gray-400 mx-auto mb-2" />
            <p class="text-gray-500">Real-time I/O performance chart</p>
            <p class="text-sm text-gray-400">Reading: {{ performance.readSpeed }} MB/s | Writing: {{ performance.writeSpeed }} MB/s</p>
          </div>
        </div>
      </div>

      <!-- Recent Activity Feed -->
      <div class="bg-white rounded-2xl shadow-lg p-6 border border-gray-100">
        <div class="flex items-center justify-between mb-6">
          <h3 class="text-xl font-bold text-gray-900">Recent Activity</h3>
          <button class="btn btn-sm btn-ghost" @click="refreshActivity">
            <TablerIcon name="refresh" class="w-4 h-4" />
          </button>
        </div>
        <div class="space-y-4 max-h-64 overflow-y-auto">
          <div v-for="(activity, index) in recentActivity" :key="index" 
               class="flex items-start gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
            <div class="p-2 rounded-lg flex-shrink-0"
                 :class="getActivityColor(activity.type)">
              <TablerIcon :name="activity.icon" class="w-4 h-4 text-white" />
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate">{{ activity.title }}</p>
              <p class="text-xs text-gray-500">{{ activity.description }}</p>
              <p class="text-xs text-gray-400 mt-1">{{ formatRelativeTime(activity.timestamp) }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Actions Section -->
    <div class="bg-white rounded-2xl shadow-lg p-8 border border-gray-100">
      <h3 class="text-xl font-bold text-gray-900 mb-6">Quick Actions</h3>
      <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
        <button v-for="action in quickActions" :key="action.name"
                class="p-4 rounded-xl border-2 border-gray-200 hover:border-tiffany hover:bg-tiffany/5 transition-all duration-200 group"
                @click="executeAction(action.action)">
          <div class="text-center">
            <div class="p-3 bg-gray-100 rounded-lg mx-auto mb-3 w-fit group-hover:bg-tiffany/10 transition-colors">
              <TablerIcon :name="action.icon" class="w-6 h-6 text-gray-600 group-hover:text-tiffany transition-colors" />
            </div>
            <p class="text-sm font-medium text-gray-700 group-hover:text-tiffany transition-colors">{{ action.name }}</p>
          </div>
        </button>
      </div>
    </div>

    <!-- Upload Modal -->
    <dialog v-if="showUploadModal" class="modal modal-open">
      <div class="modal-box w-11/12 max-w-2xl">
        <form method="dialog">
          <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2" @click="showUploadModal = false">✕</button>
        </form>
        <h3 class="font-bold text-xl mb-6">Upload Files</h3>
        
        <div class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center mb-6"
             @drop="handleDrop" @dragover.prevent @dragenter.prevent
             :class="{ 'border-tiffany bg-tiffany/5': isDragOver }">
          <TablerIcon name="cloud-upload" class="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <p class="text-lg font-medium text-gray-700 mb-2">Drag & drop files here</p>
          <p class="text-gray-500 mb-4">or click to browse</p>
          <input type="file" multiple class="file-input file-input-bordered w-full max-w-xs" @change="handleFileSelect">
        </div>

        <div v-if="uploadQueue.length > 0" class="space-y-3">
          <h4 class="font-medium">Upload Queue:</h4>
          <div v-for="file in uploadQueue" :key="file.name" class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <div class="flex items-center gap-3">
              <TablerIcon name="file" class="w-5 h-5 text-gray-500" />
              <div>
                <p class="font-medium">{{ file.name }}</p>
                <p class="text-sm text-gray-500">{{ formatFileSize(file.size) }}</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <div v-if="file.progress !== undefined" class="flex items-center gap-2">
                <progress class="progress progress-primary w-20" :value="file.progress" max="100"></progress>
                <span class="text-sm">{{ file.progress }}%</span>
              </div>
              <button class="btn btn-sm btn-ghost text-error" @click="removeFromQueue(file)">
                <TablerIcon name="x" class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        <div class="modal-action">
          <button class="btn btn-ghost" @click="showUploadModal = false">Cancel</button>
          <button class="btn btn-primary" @click="startUpload" :disabled="uploadQueue.length === 0">
            Upload {{ uploadQueue.length }} files
          </button>
        </div>
      </div>
    </dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import TablerIcon from '../components/TablerIcon.vue'

// Reactive data
const storage = ref({
  used: 2.4 * 1024 * 1024 * 1024 * 1024, // 2.4TB in bytes
  total: 8 * 1024 * 1024 * 1024 * 1024, // 8TB in bytes
  available: 5.6 * 1024 * 1024 * 1024 * 1024, // 5.6TB in bytes
  usedPercent: 30
})

const network = ref({
  throughput: 840,
  upload: 420,
  download: 920
})

const system = ref({
  cpu: 23,
  memory: 45,
  temp: 42
})

const stats = ref({
  totalFiles: 127845,
  folders: 3421,
  users: 5
})

const performance = ref({
  readSpeed: 1240,
  writeSpeed: 890
})

const chartTimeframe = ref('24h')

const recentActivity = ref([
  {
    type: 'upload',
    icon: 'upload',
    title: 'File uploaded: vacation_photos.zip',
    description: 'Uploaded to /Media/Photos',
    timestamp: new Date(Date.now() - 5 * 60 * 1000) // 5 minutes ago
  },
  {
    type: 'user',
    icon: 'user-plus',
    title: 'New user added: john_doe',
    description: 'Access granted to Media share',
    timestamp: new Date(Date.now() - 15 * 60 * 1000) // 15 minutes ago
  },
  {
    type: 'system',
    icon: 'settings',
    title: 'ZFS scrub completed',
    description: 'Pool health verification successful',
    timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000) // 2 hours ago
  },
  {
    type: 'backup',
    icon: 'backup',
    title: 'Backup job completed',
    description: '1.2TB backed up to remote storage',
    timestamp: new Date(Date.now() - 6 * 60 * 60 * 1000) // 6 hours ago
  }
])

const quickActions = ref([
  { name: 'Add Storage', icon: 'database-plus', action: 'addStorage' },
  { name: 'Create User', icon: 'user-plus', action: 'createUser' },
  { name: 'System Info', icon: 'info-circle', action: 'systemInfo' },
  { name: 'Network Test', icon: 'network', action: 'networkTest' },
  { name: 'Backup Now', icon: 'backup', action: 'backupNow' },
  { name: 'Health Check', icon: 'health-check', action: 'healthCheck' }
])

const showUploadModal = ref(false)
const uploadQueue = ref([])
const isDragOver = ref(false)

// Computed properties
const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
}

const formatRelativeTime = (date) => {
  const now = new Date()
  const diff = now - date
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)

  if (minutes < 1) return 'Just now'
  if (minutes < 60) return `${minutes}m ago`
  if (hours < 24) return `${hours}h ago`
  return `${days}d ago`
}

const getActivityColor = (type) => {
  const colors = {
    upload: 'bg-blue-500',
    user: 'bg-green-500',
    system: 'bg-purple-500',
    backup: 'bg-orange-500',
    default: 'bg-gray-500'
  }
  return colors[type] || colors.default
}

// Methods
const executeAction = (action) => {
  switch (action) {
    case 'addStorage':
      window.$toast({ message: 'Opening storage management...', type: 'info', icon: 'ti ti-database-plus' })
      break
    case 'createUser':
      window.$toast({ message: 'Opening user management...', type: 'info', icon: 'ti ti-user-plus' })
      break
    case 'systemInfo':
      window.$toast({ message: 'Loading system information...', type: 'info', icon: 'ti ti-info-circle' })
      break
    case 'networkTest':
      window.$toast({ message: 'Starting network speed test...', type: 'info', icon: 'ti ti-network' })
      break
    case 'backupNow':
      window.$toast({ message: 'Initiating backup process...', type: 'info', icon: 'ti ti-backup' })
      break
    case 'healthCheck':
      window.$toast({ message: 'Running system health check...', type: 'info', icon: 'ti ti-health-check' })
      break
  }
}

const createFolder = () => {
  const folderName = prompt('Enter folder name:')
  if (folderName) {
    window.$toast({ message: `Creating folder "${folderName}"...`, type: 'success', icon: 'ti ti-folder-plus' })
  }
}

const refreshActivity = () => {
  window.$toast({ message: 'Refreshing activity feed...', type: 'info', icon: 'ti ti-refresh' })
}

const handleDrop = (e) => {
  e.preventDefault()
  isDragOver.value = false
  const files = Array.from(e.dataTransfer.files)
  addFilesToQueue(files)
}

const handleFileSelect = (e) => {
  const files = Array.from(e.target.files)
  addFilesToQueue(files)
}

const addFilesToQueue = (files) => {
  files.forEach(file => {
    uploadQueue.value.push({
      name: file.name,
      size: file.size,
      file: file,
      progress: 0
    })
  })
}

const removeFromQueue = (fileToRemove) => {
  uploadQueue.value = uploadQueue.value.filter(file => file !== fileToRemove)
}

const startUpload = () => {
  uploadQueue.value.forEach(file => {
    simulateUpload(file)
  })
}

const simulateUpload = (file) => {
  const interval = setInterval(() => {
    file.progress += Math.random() * 20
    if (file.progress >= 100) {
      file.progress = 100
      clearInterval(interval)
      window.$toast({ message: `"${file.name}" uploaded successfully!`, type: 'success', icon: 'ti ti-check' })
    }
  }, 500)
}

// Real-time updates
let updateInterval

onMounted(() => {
  updateInterval = setInterval(() => {
    // Simulate real-time data updates
    network.value.throughput = Math.floor(Math.random() * 200) + 800
    system.value.cpu = Math.floor(Math.random() * 30) + 15
    system.value.memory = Math.floor(Math.random() * 20) + 40
    performance.value.readSpeed = Math.floor(Math.random() * 500) + 1000
    performance.value.writeSpeed = Math.floor(Math.random() * 300) + 700
  }, 3000)
})

onUnmounted(() => {
  if (updateInterval) {
    clearInterval(updateInterval)
  }
})
</script>

<style scoped>
.btn-active {
  @apply bg-tiffany text-white;
}
</style> 
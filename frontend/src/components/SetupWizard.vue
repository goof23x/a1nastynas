<template>
  <div class="fixed inset-0 bg-black bg-opacity-60 z-50 flex items-center justify-center p-4">
    <div class="bg-base-100 rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
      <!-- Progress Header -->
      <div class="bg-gradient-to-r from-tiffany to-tiffany-dark p-6 text-white">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold flex items-center gap-3">
              <img src="/a1nas.png" alt="A1NAS" class="w-8 h-8 rounded">
              A1NAS Setup Wizard
            </h1>
            <p class="text-tiffany-100 mt-1">Let's get your NAS running in minutes!</p>
          </div>
          <div class="text-right">
            <div class="text-sm opacity-90">Step {{ currentStep }} of {{ totalSteps }}</div>
            <div class="w-48 bg-tiffany-dark rounded-full h-2 mt-2">
              <div class="bg-white h-2 rounded-full transition-all duration-300" 
                   :style="{ width: (currentStep / totalSteps) * 100 + '%' }"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Step Content -->
      <div class="p-8 overflow-y-auto max-h-[calc(90vh-140px)]">
        <!-- Step 1: Welcome & Mode Selection -->
        <div v-if="currentStep === 1" class="space-y-6">
          <div class="text-center mb-8">
            <TablerIcon name="rocket" class="w-16 h-16 text-tiffany mx-auto mb-4" />
            <h2 class="text-3xl font-bold mb-2">Welcome to A1NAS!</h2>
            <p class="text-gray-600 text-lg">Choose your setup experience level</p>
          </div>

          <div class="grid md:grid-cols-2 gap-6">
            <!-- Simple Mode -->
            <div class="cursor-pointer p-6 border-2 rounded-lg transition-all hover:shadow-lg"
                 :class="setupMode === 'simple' ? 'border-tiffany bg-tiffany/10' : 'border-gray-200'"
                 @click="setupMode = 'simple'">
              <div class="flex items-center mb-4">
                <TablerIcon name="magic-wand" class="w-8 h-8 text-tiffany mr-3" />
                <h3 class="text-xl font-bold">🪄 Simple Setup</h3>
              </div>
              <p class="text-gray-600 mb-4">Perfect for first-time users. We'll handle everything automatically with smart defaults.</p>
              <div class="space-y-2 text-sm text-gray-500">
                <div class="flex items-center">
                  <TablerIcon name="check" class="w-4 h-4 text-green-500 mr-2" />
                  <span>Auto-detect drives</span>
                </div>
                <div class="flex items-center">
                  <TablerIcon name="check" class="w-4 h-4 text-green-500 mr-2" />
                  <span>Smart RAID selection</span>
                </div>
                <div class="flex items-center">
                  <TablerIcon name="check" class="w-4 h-4 text-green-500 mr-2" />
                  <span>Optimized settings</span>
                </div>
              </div>
            </div>

            <!-- Advanced Mode -->
            <div class="cursor-pointer p-6 border-2 rounded-lg transition-all hover:shadow-lg"
                 :class="setupMode === 'advanced' ? 'border-tiffany bg-tiffany/10' : 'border-gray-200'"
                 @click="setupMode = 'advanced'">
              <div class="flex items-center mb-4">
                <TablerIcon name="settings" class="w-8 h-8 text-tiffany mr-3" />
                <h3 class="text-xl font-bold">⚙️ Advanced Setup</h3>
              </div>
              <p class="text-gray-600 mb-4">Full control over storage, networking, and performance settings.</p>
              <div class="space-y-2 text-sm text-gray-500">
                <div class="flex items-center">
                  <TablerIcon name="check" class="w-4 h-4 text-green-500 mr-2" />
                  <span>Custom RAID layouts</span>
                </div>
                <div class="flex items-center">
                  <TablerIcon name="check" class="w-4 h-4 text-green-500 mr-2" />
                  <span>Performance tuning</span>
                </div>
                <div class="flex items-center">
                  <TablerIcon name="check" class="w-4 h-4 text-green-500 mr-2" />
                  <span>Network configuration</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Step 2: Drive Detection -->
        <div v-if="currentStep === 2" class="space-y-6">
          <div class="text-center mb-8">
            <TablerIcon name="scan" class="w-16 h-16 text-tiffany mx-auto mb-4 animate-spin" />
            <h2 class="text-3xl font-bold mb-2">Detecting Your Drives</h2>
            <p class="text-gray-600 text-lg">Scanning for storage devices...</p>
          </div>

          <div class="bg-gray-50 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-4">Found Drives:</h3>
            <div class="grid gap-4">
              <div v-for="drive in detectedDrives" :key="drive.device" 
                   class="flex items-center justify-between p-4 bg-white rounded-lg border">
                <div class="flex items-center">
                  <div class="w-3 h-3 rounded-full mr-3"
                       :class="drive.type === 'nvme' ? 'bg-purple-500' : 
                              drive.type === 'ssd' ? 'bg-blue-500' : 'bg-green-500'"></div>
                  <div>
                    <div class="font-medium">{{ drive.device }} - {{ drive.size }}</div>
                    <div class="text-sm text-gray-500">{{ drive.model }} ({{ drive.type.toUpperCase() }})</div>
                  </div>
                </div>
                <div class="flex items-center">
                  <span class="text-sm text-green-600 mr-2">✓ Healthy</span>
                  <span class="text-xs bg-gray-100 px-2 py-1 rounded">{{ drive.temp }}°C</span>
                </div>
              </div>
            </div>
          </div>

          <div v-if="setupMode === 'simple'" class="bg-tiffany/10 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-2 text-tiffany">🤖 Smart Recommendation</h3>
            <p class="text-gray-700">{{ smartRecommendation }}</p>
          </div>
        </div>

        <!-- Step 3: Storage Configuration -->
        <div v-if="currentStep === 3" class="space-y-6">
          <div class="text-center mb-8">
            <TablerIcon name="database" class="w-16 h-16 text-tiffany mx-auto mb-4" />
            <h2 class="text-3xl font-bold mb-2">Configure Your Storage</h2>
            <p class="text-gray-600 text-lg">Set up your storage pools for optimal performance</p>
          </div>

          <div v-if="setupMode === 'simple'" class="space-y-4">
            <div class="bg-gradient-to-r from-green-50 to-blue-50 rounded-lg p-6 border border-green-200">
              <h3 class="text-lg font-semibold mb-4 text-green-800">✨ Recommended Configuration</h3>
              <div class="space-y-3">
                <div class="flex justify-between items-center">
                  <span>Main Storage Pool:</span>
                  <span class="font-medium">{{ recommendedConfig.mainPool }}</span>
                </div>
                <div class="flex justify-between items-center" v-if="recommendedConfig.cachePool">
                  <span>Cache Pool:</span>
                  <span class="font-medium">{{ recommendedConfig.cachePool }}</span>
                </div>
                <div class="flex justify-between items-center">
                  <span>Total Usable Space:</span>
                  <span class="font-medium text-green-600">{{ recommendedConfig.usableSpace }}</span>
                </div>
              </div>
            </div>
          </div>

          <div v-if="setupMode === 'advanced'" class="space-y-6">
            <!-- Advanced storage configuration would go here -->
            <div class="alert alert-info">
              <TablerIcon name="info-circle" class="w-5 h-5" />
              <span>Advanced configuration panel would be implemented here with full ZFS options</span>
            </div>
          </div>
        </div>

        <!-- Step 4: Performance Optimization -->
        <div v-if="currentStep === 4" class="space-y-6">
          <div class="text-center mb-8">
            <TablerIcon name="bolt" class="w-16 h-16 text-tiffany mx-auto mb-4" />
            <h2 class="text-3xl font-bold mb-2">Performance Optimization</h2>
            <p class="text-gray-600 text-lg">Tuning your system for maximum speed</p>
          </div>

          <div class="grid md:grid-cols-3 gap-4">
            <div class="text-center p-6 bg-gradient-to-br from-purple-50 to-purple-100 rounded-lg">
              <TablerIcon name="cpu" class="w-8 h-8 text-purple-600 mx-auto mb-2" />
              <h4 class="font-semibold">CPU Optimization</h4>
              <p class="text-sm text-gray-600 mt-1">NVMe queue tuning</p>
            </div>
            <div class="text-center p-6 bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg">
              <TablerIcon name="memory" class="w-8 h-8 text-blue-600 mx-auto mb-2" />
              <h4 class="font-semibold">Memory Tuning</h4>
              <p class="text-sm text-gray-600 mt-1">ZFS ARC optimization</p>
            </div>
            <div class="text-center p-6 bg-gradient-to-br from-green-50 to-green-100 rounded-lg">
              <TablerIcon name="lightning-bolt" class="w-8 h-8 text-green-600 mx-auto mb-2" />
              <h4 class="font-semibold">Storage Acceleration</h4>
              <p class="text-sm text-gray-600 mt-1">Cache configuration</p>
            </div>
          </div>

          <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <div class="flex items-start">
              <TablerIcon name="wand" class="w-5 h-5 text-yellow-600 mr-3 mt-0.5" />
              <div>
                <h4 class="font-semibold text-yellow-800">Auto-tuning in progress...</h4>
                <p class="text-yellow-700 text-sm mt-1">Optimizing based on your hardware configuration</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Step 5: Final Setup -->
        <div v-if="currentStep === 5" class="space-y-6">
          <div class="text-center mb-8">
            <TablerIcon name="check-circle" class="w-16 h-16 text-green-500 mx-auto mb-4" />
            <h2 class="text-3xl font-bold mb-2">Almost Ready!</h2>
            <p class="text-gray-600 text-lg">Final setup and user account creation</p>
          </div>

          <div class="bg-gradient-to-r from-tiffany/10 to-blue/10 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-4">Create Admin Account</h3>
            <div class="grid md:grid-cols-2 gap-4">
              <div>
                <label class="label">
                  <span class="label-text">Username</span>
                </label>
                <input v-model="adminUser.username" type="text" class="input input-bordered w-full" 
                       placeholder="admin" />
              </div>
              <div>
                <label class="label">
                  <span class="label-text">Password</span>
                </label>
                <input v-model="adminUser.password" type="password" class="input input-bordered w-full" />
                <div class="text-xs text-gray-500 mt-1">Minimum 8 characters, mixed case + numbers</div>
              </div>
            </div>
          </div>

          <div class="bg-blue-50 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-4 text-blue-800">🎯 Quick Access URLs</h3>
            <div class="space-y-2 text-sm">
              <div><span class="font-medium">Web Interface:</span> https://{{ networkInfo.hostname }}.local</div>
              <div><span class="font-medium">IP Address:</span> https://{{ networkInfo.ip }}</div>
              <div><span class="font-medium">Mobile App:</span> Scan QR code (coming soon)</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Navigation Footer -->
      <div class="bg-gray-50 px-8 py-4 flex justify-between items-center">
        <button class="btn btn-ghost" 
                @click="previousStep" 
                :disabled="currentStep === 1">
          <TablerIcon name="arrow-left" class="w-4 h-4 mr-2" />
          Back
        </button>

        <div class="flex gap-2">
          <button v-for="step in totalSteps" :key="step"
                  class="w-2 h-2 rounded-full transition-colors"
                  :class="step <= currentStep ? 'bg-tiffany' : 'bg-gray-300'"></button>
        </div>

        <button class="btn btn-primary" 
                @click="nextStep"
                :disabled="!canProceed">
          <span v-if="currentStep < totalSteps">Next</span>
          <span v-else>Finish Setup</span>
          <TablerIcon name="arrow-right" class="w-4 h-4 ml-2" />
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import TablerIcon from './TablerIcon.vue'

const emit = defineEmits(['close', 'complete'])

const currentStep = ref(1)
const totalSteps = 5
const setupMode = ref('simple')

const detectedDrives = ref([])
const networkInfo = ref({ hostname: 'a1nas', ip: '192.168.1.100' })
const adminUser = ref({ username: 'admin', password: '' })

const smartRecommendation = computed(() => {
  if (!detectedDrives.value.length) return 'Scanning drives...'
  
  const nvmeCount = detectedDrives.value.filter(d => d.type === 'nvme').length
  const ssdCount = detectedDrives.value.filter(d => d.type === 'ssd').length
  const hddCount = detectedDrives.value.filter(d => d.type === 'hdd').length

  if (nvmeCount >= 2) {
    return `Perfect! We'll use your ${nvmeCount} NVMe drives in a high-performance mirror configuration with automatic cache optimization.`
  } else if (ssdCount >= 2) {
    return `Great setup! We'll configure your ${ssdCount} SSDs in RAID-1 for reliability with excellent performance.`
  } else if (hddCount >= 3) {
    return `We'll set up your ${hddCount} drives in RAID-Z for optimal balance of storage space and data protection.`
  }
  return 'We\'ll configure the best possible setup with your available drives.'
})

const recommendedConfig = computed(() => {
  const nvmeCount = detectedDrives.value.filter(d => d.type === 'nvme').length
  const totalSize = detectedDrives.value.reduce((sum, d) => sum + parseFloat(d.size), 0)
  
  return {
    mainPool: nvmeCount >= 2 ? 'NVMe Mirror (Ultra-Fast)' : 'Mixed RAID-Z (Balanced)',
    cachePool: nvmeCount > 2 ? 'Dedicated NVMe Cache' : null,
    usableSpace: Math.floor(totalSize * 0.8) + ' GB'
  }
})

const canProceed = computed(() => {
  switch (currentStep.value) {
    case 1: return setupMode.value !== null
    case 2: return detectedDrives.value.length > 0
    case 5: return adminUser.value.username && adminUser.value.password.length >= 8
    default: return true
  }
})

const nextStep = () => {
  if (currentStep.value < totalSteps) {
    currentStep.value++
    if (currentStep.value === 2) {
      setTimeout(detectDrives, 1000) // Simulate drive detection
    }
  } else {
    completeSetup()
  }
}

const previousStep = () => {
  if (currentStep.value > 1) {
    currentStep.value--
  }
}

const detectDrives = () => {
  // Simulate drive detection
  detectedDrives.value = [
    { device: '/dev/nvme0n1', size: '1TB', type: 'nvme', model: 'Samsung 980 PRO', temp: 45 },
    { device: '/dev/nvme1n1', size: '1TB', type: 'nvme', model: 'Samsung 980 PRO', temp: 42 },
    { device: '/dev/sda', size: '4TB', type: 'hdd', model: 'WD Red Plus', temp: 38 },
    { device: '/dev/sdb', size: '4TB', type: 'hdd', model: 'WD Red Plus', temp: 36 }
  ]
}

const completeSetup = () => {
  emit('complete', {
    mode: setupMode.value,
    drives: detectedDrives.value,
    admin: adminUser.value
  })
}

onMounted(() => {
  // Initialize any needed data
})
</script>

<style scoped>
.tiffany-dark {
  @apply bg-teal-600;
}
.tiffany-100 {
  @apply text-teal-100;
}
</style>
<template>
  <div class="space-y-8">
    <div class="bg-white rounded-lg shadow p-6">
      <h3 class="text-lg font-bold mb-4 text-tiffany">General Settings</h3>
      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <span class="flex items-center gap-2"><TablerIcon name="moon" class="w-5 h-5 text-tiffany" /> Dark Mode</span>
          <input type="checkbox" class="toggle toggle-primary" v-model="settings.darkMode" @change="toggleDarkMode" />
        </div>
        <div class="flex items-center justify-between">
          <span class="flex items-center gap-2"><TablerIcon name="language" class="w-5 h-5 text-tiffany" /> Language</span>
          <select class="select select-bordered w-32" v-model="settings.language">
            <option value="en">English</option>
            <option value="es">Español</option>
            <option value="fr">Français</option>
          </select>
        </div>
        <div class="flex items-center justify-between">
          <span class="flex items-center gap-2"><TablerIcon name="lock" class="w-5 h-5 text-tiffany" /> Require Login</span>
          <input type="checkbox" class="toggle toggle-primary" v-model="settings.requireLogin" />
        </div>
      </div>
    </div>
    <div class="bg-white rounded-lg shadow p-6 flex items-center gap-4">
      <TablerIcon name="brand-docker" class="w-7 h-7 text-tiffany" />
      <div class="flex-1">
        <h3 class="text-base font-medium text-gray-900">Docker</h3>
        <p class="text-sm text-gray-500">Install Docker to enable app management and containers.</p>
      </div>
      <button
        v-if="!dockerInstalled && !installingDocker"
        @click="installDocker"
        class="btn btn-primary min-w-[120px]"
      >
        Install Docker
      </button>
      <span v-if="dockerInstalled" class="text-green-600 font-semibold">Installed</span>
      <span v-if="installingDocker" class="text-tiffany animate-pulse">Installing...</span>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import TablerIcon from '../components/TablerIcon.vue'
// import { settingsApi, systemApi } from '@/services/api' // Uncomment and use real API

const settings = ref({ darkMode: true, language: 'en', requireLogin: true })
const dockerInstalled = ref(false)
const installingDocker = ref(false)

const checkDocker = async () => {
  // TODO: Replace with real API call
  dockerInstalled.value = false
}
const installDocker = async () => {
  installingDocker.value = true
  setTimeout(() => {
    dockerInstalled.value = true
    installingDocker.value = false
    window.$toast({ message: 'Docker installed successfully!', type: 'success', icon: 'ti ti-brand-docker' })
  }, 2000)
  // TODO: Call real install API
}
const toggleDarkMode = () => {
  document.documentElement.classList.toggle('dark', settings.value.darkMode)
}
onMounted(() => {
  checkDocker()
  toggleDarkMode()
})
</script> 
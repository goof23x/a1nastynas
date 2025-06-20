<template>
  <div class="min-h-screen bg-base-100 text-base-content flex">
    <!-- Setup Wizard (First Time Users) -->
    <SetupWizard v-if="showSetupWizard" @close="dismissSetupWizard" @complete="completeSetup" />
    
    <!-- Onboarding Modal -->
    <OnboardingModal :show="showOnboarding" @close="dismissOnboarding" />
    
    <!-- Global Toaster -->
    <GlobalToaster />
    
    <!-- Undo Snackbar -->
    <UndoSnackbar :show="undo.show" :message="undo.message" @undo="undo.action" @close="undo.show = false" />
    
    <!-- Sidebar (drawer on mobile) -->
    <div>
      <div
        class="fixed inset-0 bg-black bg-opacity-40 z-40 md:hidden transition-opacity"
        v-if="sidebarOpen"
        @click="sidebarOpen = false"
      ></div>
      <aside
        :class="[
          'fixed md:static z-50 md:z-auto top-0 left-0 h-full w-64 bg-neutral flex flex-col py-6 px-4 border-r border-base-200 transition-transform duration-200',
          sidebarOpen ? 'translate-x-0' : '-translate-x-full',
          'md:translate-x-0'
        ]"
      >
        <div class="flex items-center mb-8">
          <img src="/a1nas.png" alt="A1Nas Logo" class="h-10 w-10 rounded mr-3" />
          <span class="text-2xl font-bold text-tiffany">a1nas</span>
        </div>
        <nav class="flex-1 space-y-2">
          <SidebarLink to="/dashboard" icon="dashboard" label="Dashboard" />
          <SidebarLink to="/storage" icon="hard-drive" label="Storage" />
          <SidebarLink to="/explorer" icon="folder" label="Explorer" />
          <SidebarLink to="/users" icon="users" label="Users" />
          <SidebarLink to="/docker" icon="brand-docker" label="Docker" />
          <SidebarLink to="/system" icon="tool" label="System" />
          <SidebarLink to="/settings" icon="settings" label="Settings" />
        </nav>
        
        <!-- System Status Footer -->
        <div class="mt-auto">
          <div class="bg-base-200 rounded-lg p-3 text-sm">
            <div class="flex items-center justify-between mb-2">
              <span class="text-gray-600">System Status</span>
              <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
            </div>
            <div class="space-y-1 text-xs text-gray-500">
              <div class="flex justify-between">
                <span>CPU:</span>
                <span>{{ systemStatus.cpu }}%</span>
              </div>
              <div class="flex justify-between">
                <span>RAM:</span>
                <span>{{ systemStatus.memory }}%</span>
              </div>
              <div class="flex justify-between">
                <span>Storage:</span>
                <span>{{ systemStatus.storage }}%</span>
              </div>
            </div>
          </div>
        </div>
      </aside>
    </div>
    
    <!-- Main Content -->
    <div class="flex-1 flex flex-col">
      <!-- Topbar -->
      <header class="flex items-center justify-between px-4 md:px-8 py-4 border-b border-base-200 bg-base-100">
        <div class="flex items-center gap-2">
          <button class="btn btn-ghost btn-circle md:hidden min-w-[44px] min-h-[44px]" @click="sidebarOpen = true">
            <TablerIcon name="menu-2" class="w-6 h-6" />
          </button>
          <input type="text" placeholder="Search files, settings..." 
                 class="input input-bordered w-32 sm:w-64 bg-base-200 min-h-[44px]" 
                 v-model="searchQuery"
                 @keyup.enter="performSearch" />
        </div>
        
        <div class="flex items-center gap-4">
          <!-- Performance Indicator -->
          <div class="hidden sm:flex items-center gap-2 bg-base-200 rounded-lg px-3 py-2">
            <div class="w-2 h-2 rounded-full" :class="getPerformanceColor()"></div>
            <span class="text-xs font-medium">{{ performanceStatus }}</span>
          </div>
          
          <!-- Quick Actions -->
          <div class="dropdown dropdown-end">
            <button tabindex="0" class="btn btn-ghost btn-circle min-w-[44px] min-h-[44px]">
              <TablerIcon name="plus" class="w-6 h-6" />
            </button>
            <ul tabindex="0" class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52">
              <li><a @click="quickAction('upload')"><TablerIcon name="upload" class="w-4 h-4" />Upload Files</a></li>
              <li><a @click="quickAction('folder')"><TablerIcon name="folder-plus" class="w-4 h-4" />New Folder</a></li>
              <li><a @click="quickAction('user')"><TablerIcon name="user-plus" class="w-4 h-4" />Add User</a></li>
              <li><a @click="quickAction('backup')"><TablerIcon name="backup" class="w-4 h-4" />Backup Now</a></li>
            </ul>
          </div>
          
          <!-- Notifications -->
          <div class="dropdown dropdown-end">
            <button tabindex="0" class="btn btn-ghost btn-circle min-w-[44px] min-h-[44px] relative">
              <TablerIcon name="bell" class="w-6 h-6" />
              <span v-if="notifications.length > 0" class="badge badge-primary badge-xs absolute -top-1 -right-1">
                {{ notifications.length }}
              </span>
            </button>
            <div tabindex="0" class="dropdown-content z-[1] bg-base-100 rounded-box w-80 shadow-lg">
              <div class="p-4 border-b border-base-200">
                <h3 class="font-semibold">Notifications</h3>
              </div>
              <div class="max-h-64 overflow-y-auto">
                <div v-for="notification in notifications" :key="notification.id" 
                     class="p-3 border-b border-base-200 hover:bg-base-200 transition-colors">
                  <div class="flex items-start gap-3">
                    <TablerIcon :name="notification.icon" class="w-5 h-5 text-tiffany flex-shrink-0 mt-0.5" />
                    <div class="flex-1">
                      <p class="text-sm font-medium">{{ notification.title }}</p>
                      <p class="text-xs text-gray-500">{{ notification.message }}</p>
                      <p class="text-xs text-gray-400 mt-1">{{ formatTime(notification.time) }}</p>
                    </div>
                  </div>
                </div>
                <div v-if="notifications.length === 0" class="p-4 text-center text-gray-500">
                  <TablerIcon name="bell-off" class="w-8 h-8 mx-auto mb-2 opacity-50" />
                  <p>No new notifications</p>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Theme Toggle -->
          <button class="btn btn-ghost btn-circle min-w-[44px] min-h-[44px]" @click="toggleDarkMode">
            <TablerIcon :name="isDark ? 'sun' : 'moon'" class="w-6 h-6" />
          </button>
          
          <!-- User Avatar -->
          <div class="dropdown dropdown-end">
            <button tabindex="0" class="avatar placeholder min-w-[44px] min-h-[44px]">
              <div class="bg-tiffany text-base-content rounded-full w-10 h-10 flex items-center justify-center">
                <span class="text-sm font-bold">{{ user.initials }}</span>
              </div>
            </button>
            <ul tabindex="0" class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52">
              <li class="menu-title">
                <span>{{ user.name }}</span>
              </li>
              <li><a @click="openProfile"><TablerIcon name="user" class="w-4 h-4" />Profile</a></li>
              <li><a @click="openSettings"><TablerIcon name="settings" class="w-4 h-4" />Settings</a></li>
              <li><a @click="logout"><TablerIcon name="logout" class="w-4 h-4" />Logout</a></li>
            </ul>
          </div>
        </div>
      </header>
      
      <!-- Main Content Area -->
      <main class="flex-1 p-2 sm:p-4 md:p-8 bg-base-100 overflow-y-auto">
        <router-view />
      </main>
    </div>

    <!-- Global Loading Overlay -->
    <div v-if="isLoading" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
      <div class="bg-base-100 rounded-lg p-6 flex items-center gap-4">
        <span class="loading loading-spinner loading-lg text-tiffany"></span>
        <span class="text-lg">{{ loadingMessage }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import TablerIcon from './components/TablerIcon.vue';
import SidebarLink from './components/SidebarLink.vue';
import OnboardingModal from './components/OnboardingModal.vue';
import SetupWizard from './components/SetupWizard.vue';
import GlobalToaster from './components/GlobalToaster.vue';
import UndoSnackbar from './components/UndoSnackbar.vue';

const router = useRouter();

// Theme management
const isDark = ref(true);
function toggleDarkMode() {
  isDark.value = !isDark.value;
  document.documentElement.classList.toggle('dark', isDark.value);
  localStorage.setItem('a1nas_dark_mode', isDark.value);
}

// Setup wizard state
const showSetupWizard = ref(false);
const isFirstTimeSetup = ref(false);

// Onboarding modal logic
const showOnboarding = ref(false);
onMounted(() => {
  // Check if first time setup
  const hasSetup = localStorage.getItem('a1nas_setup_complete');
  if (!hasSetup) {
    showSetupWizard.value = true;
    isFirstTimeSetup.value = true;
  } else if (!localStorage.getItem('a1nas_onboarded')) {
    showOnboarding.value = true;
  }

  // Load theme preference
  const darkMode = localStorage.getItem('a1nas_dark_mode');
  if (darkMode !== null) {
    isDark.value = darkMode === 'true';
    document.documentElement.classList.toggle('dark', isDark.value);
  }

  // Initialize system monitoring
  connectWebSocket();
});

function dismissOnboarding() {
  showOnboarding.value = false;
  localStorage.setItem('a1nas_onboarded', '1');
}

function dismissSetupWizard() {
  showSetupWizard.value = false;
  localStorage.setItem('a1nas_setup_complete', '1');
}

function completeSetup(setupData) {
  console.log('Setup completed:', setupData);
  dismissSetupWizard();
  
  // Show success message
  window.$toast?.({ 
    message: 'A1NAS setup completed successfully! Welcome to your new NAS.', 
    type: 'success', 
    icon: 'ti ti-check-circle',
    duration: 5000
  });
  
  // Redirect to dashboard
  router.push('/dashboard');
}

// User state
const user = reactive({
  name: 'Admin User',
  initials: 'AU',
  email: 'admin@a1nas.local'
});

// System status
const systemStatus = reactive({
  cpu: 23,
  memory: 45,
  storage: 67
});

// Performance status
const performanceStatus = computed(() => {
  const avgLoad = (systemStatus.cpu + systemStatus.memory + systemStatus.storage) / 3;
  if (avgLoad < 30) return 'Optimal';
  if (avgLoad < 60) return 'Good';
  if (avgLoad < 80) return 'Fair';
  return 'High Load';
});

function getPerformanceColor() {
  const avgLoad = (systemStatus.cpu + systemStatus.memory + systemStatus.storage) / 3;
  if (avgLoad < 30) return 'bg-green-500';
  if (avgLoad < 60) return 'bg-blue-500';
  if (avgLoad < 80) return 'bg-yellow-500';
  return 'bg-red-500';
}

// Search functionality
const searchQuery = ref('');
function performSearch() {
  if (searchQuery.value.trim()) {
    console.log('Searching for:', searchQuery.value);
    window.$toast?.({ 
      message: `Searching for "${searchQuery.value}"...`, 
      type: 'info', 
      icon: 'ti ti-search' 
    });
  }
}

// Notifications
const notifications = ref([
  {
    id: 1,
    icon: 'upload',
    title: 'File Upload Complete',
    message: 'vacation_photos.zip uploaded successfully',
    time: new Date(Date.now() - 5 * 60 * 1000)
  },
  {
    id: 2,
    icon: 'shield-check',
    title: 'Backup Completed',
    message: '1.2TB backed up to remote storage',
    time: new Date(Date.now() - 2 * 60 * 60 * 1000)
  }
]);

function formatTime(date) {
  const now = new Date();
  const diff = now - date;
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return 'Just now';
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(diff / 3600000);
  if (hours < 24) return `${hours}h ago`;
  return date.toLocaleDateString();
}

// Quick actions
function quickAction(action) {
  switch (action) {
    case 'upload':
      window.$toast?.({ message: 'Opening file upload...', type: 'info', icon: 'ti ti-upload' });
      break;
    case 'folder':
      const folderName = prompt('Enter folder name:');
      if (folderName) {
        window.$toast?.({ message: `Creating folder "${folderName}"...`, type: 'success', icon: 'ti ti-folder-plus' });
      }
      break;
    case 'user':
      window.$toast?.({ message: 'Opening user management...', type: 'info', icon: 'ti ti-user-plus' });
      break;
    case 'backup':
      window.$toast?.({ message: 'Starting backup process...', type: 'info', icon: 'ti ti-backup' });
      break;
  }
}

// User actions
function openProfile() {
  router.push('/profile');
}

function openSettings() {
  router.push('/settings');
}

function logout() {
  localStorage.removeItem('a1nas_token');
  window.$toast?.({ message: 'Logged out successfully', type: 'success', icon: 'ti ti-logout' });
  router.push('/login');
}

// WebSocket connection for real-time updates
let ws = null;
function connectWebSocket() {
  try {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = window.location.host;
    ws = new WebSocket(`${protocol}//${host}/api/system/performance`);
    
    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        // Update system status from real-time data
        systemStatus.cpu = Math.round(data.cpu_usage || 0);
        systemStatus.memory = Math.round(data.memory_usage || 0);
        systemStatus.storage = Math.round(((data.zfs_stats?.pools?.[0]?.used || 0) / (data.zfs_stats?.pools?.[0]?.size || 1)) * 100);
      } catch (e) {
        console.warn('Failed to parse WebSocket data:', e);
      }
    };
    
    ws.onclose = () => {
      // Reconnect after 5 seconds
      setTimeout(connectWebSocket, 5000);
    };
  } catch (e) {
    console.warn('WebSocket connection failed:', e);
  }
}

// Global loading state
const isLoading = ref(false);
const loadingMessage = ref('');

// Undo snackbar state
const undo = reactive({ show: false, message: '', action: () => {} });

// Sidebar mobile state
const sidebarOpen = ref(false);
</script>

<style>
body {
  font-family: 'Inter', sans-serif;
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: #f1f1f1;
}

::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}

/* Animation for smooth transitions */
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style> 
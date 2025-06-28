<template>
  <div class="min-h-screen bg-base-100 text-base-content flex">
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
          <SidebarLink icon="dashboard" label="Dashboard" />
          <SidebarLink icon="hard-drive" label="Drives" />
          <SidebarLink icon="folder" label="Explorer" />
          <SidebarLink icon="users" label="Users" />
          <SidebarLink icon="brand-docker" label="Docker" />
          <SidebarLink icon="tool" label="Tools" />
          <SidebarLink icon="settings" label="Settings" />
        </nav>
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
          <input type="text" placeholder="Search..." class="input input-bordered w-32 sm:w-64 bg-base-200 min-h-[44px]" />
        </div>
        <div class="flex items-center gap-4">
          <button class="btn btn-ghost btn-circle min-w-[44px] min-h-[44px]" @click="toggleDarkMode">
            <TablerIcon :name="isDark ? 'sun' : 'moon'" class="w-6 h-6" />
          </button>
          <div class="avatar placeholder min-w-[44px] min-h-[44px]">
            <div class="bg-tiffany text-base-content rounded-full w-10 h-10 flex items-center justify-center">
              <span>U</span>
            </div>
          </div>
        </div>
      </header>
      <!-- Main slot -->
      <main class="flex-1 p-2 sm:p-4 md:p-8 bg-base-100">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import TablerIcon from './components/TablerIcon.vue';
import SidebarLink from './components/SidebarLink.vue';
import OnboardingModal from './components/OnboardingModal.vue';
import GlobalToaster from './components/GlobalToaster.vue';
import UndoSnackbar from './components/UndoSnackbar.vue';

const isDark = ref(true);
function toggleDarkMode() {
  isDark.value = !isDark.value;
  document.documentElement.classList.toggle('dark', isDark.value);
}

// Onboarding modal logic
const showOnboarding = ref(false);
onMounted(() => {
  if (!localStorage.getItem('a1nas_onboarded')) {
    showOnboarding.value = true;
  }
});
function dismissOnboarding() {
  showOnboarding.value = false;
  localStorage.setItem('a1nas_onboarded', '1');
}

// Undo snackbar state (to be used by actions)
const undo = reactive({ show: false, message: '', action: () => {} });

// Sidebar mobile state
const sidebarOpen = ref(false);
</script>

<style>
body {
  font-family: 'Inter', sans-serif;
}
</style> 
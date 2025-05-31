import { createRouter, createWebHistory } from 'vue-router'
import { authApi } from '../services/api'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    name: 'Dashboard',
    component: () => import('../views/Dashboard.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/storage',
    name: 'Storage',
    component: () => import('../views/Storage.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/docker',
    name: 'Docker',
    component: () => import('../views/Docker.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/system',
    name: 'System',
    component: () => import('../views/System.vue'),
    meta: { requiresAuth: true }
  },
  { path: '/drives', name: 'Drives', component: { template: '<div>Drives Management (Coming Soon)</div>' } },
  { path: '/explorer', name: 'Explorer', component: { template: '<div>File Explorer (Coming Soon)</div>' } },
  { path: '/users', name: 'Users', component: { template: '<div>User & Group Management (Coming Soon)</div>' } },
  { path: '/tools', name: 'Tools', component: { template: '<div>System Tools & Diagnostics (Coming Soon)</div>' } },
  { path: '/settings', name: 'Settings', component: { template: '<div>Settings (Coming Soon)</div>' } },
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Navigation guard
router.beforeEach((to, from, next) => {
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)
  const isAuthenticated = authApi.isAuthenticated()

  if (requiresAuth && !isAuthenticated) {
    next('/login')
  } else if (to.path === '/login' && isAuthenticated) {
    next('/')
  } else {
    next()
  }
})

export default router 
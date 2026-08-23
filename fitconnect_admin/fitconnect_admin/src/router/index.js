import { createRouter, createWebHistory } from 'vue-router'
import { supabase } from '../lib/supabaseClient'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue')
    },
    {
      path: '/', // <--- ADD THIS: The "Home" path
      name: 'dashboard',
      component: () => import('../views/HomeView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/matches',
      name: 'matches',
      component: () => import('../views/MatchesView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/users',
      name: 'users',
      component: () => import('../views/UsersView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/reports',
      name: 'reports',
      component: () => import('../views/ReportsView.vue'),
      meta: { requiresAuth: true }
    },
    // OPTIONAL: Redirect any unknown path to home
    {
      path: '/:pathMatch(.*)*',
      redirect: '/'
    }
  ]
})

// NAVIGATION GUARD
router.beforeEach(async (to, from, next) => {
  const { data: { session } } = await supabase.auth.getSession()

  // 1. If trying to access protected page without login
  if (to.meta.requiresAuth && !session) {
    next('/login')
  } 
  // 2. If already logged in but trying to go to login page
  else if (to.path === '/login' && session) {
    next('/')
  }
  // 3. Otherwise, proceed
  else {
    next()
  }
})

export default router
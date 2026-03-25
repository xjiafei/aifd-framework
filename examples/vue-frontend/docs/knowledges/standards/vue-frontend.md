# Vue 前端编码规范

## 组件规范

### 必须使用 Composition API + `<script setup>`

```vue
<!-- 正确 -->
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()
const loading = ref(false)
const userList = computed(() => userStore.users)

onMounted(() => {
  fetchUsers()
})

async function fetchUsers() {
  loading.value = true
  try {
    await userStore.fetchUsers()
  } finally {
    loading.value = false
  }
}
</script>
```

**禁止使用 Options API**（`data()`, `methods`, `computed` 等选项式写法）。

### 单文件组件（SFC）结构顺序

```vue
<script setup lang="ts">
// 1. imports
// 2. props / emits 定义
// 3. 响应式变量（ref / reactive）
// 4. computed
// 5. watch / watchEffect
// 6. 生命周期钩子
// 7. 方法
// 8. defineExpose（如需要）
</script>

<template>
  <!-- HTML 模板 -->
</template>

<style scoped lang="scss">
/* 组件样式 */
</style>
```

### 组件大小限制

- 单个 `.vue` 文件不超过 **300 行**
- 超过 300 行需拆分为子组件或抽取 composable
- `<template>` 部分不超过 **100 行**

## 命名规范

### 文件命名

| 类别 | 命名风格 | 示例 |
|------|---------|------|
| 组件文件 | PascalCase | `UserList.vue`, `OrderDetail.vue` |
| composable 文件 | camelCase + `use` 前缀 | `useUserList.ts`, `usePagination.ts` |
| store 文件 | camelCase | `user.ts`, `order.ts` |
| 工具函数 | camelCase | `formatDate.ts`, `validate.ts` |
| 类型定义 | camelCase | `user.d.ts`, `api.d.ts` |
| 页面文件 | PascalCase 或 kebab-case 目录 | `views/user/UserList.vue` |

### 代码命名

| 类别 | 命名风格 | 示例 |
|------|---------|------|
| 组件名 | PascalCase | `<UserList />`, `<OrderDetail />` |
| props | camelCase | `userId`, `pageSize` |
| emits | kebab-case | `@update-user`, `@page-change` |
| ref 变量 | camelCase | `const loading = ref(false)` |
| composable | `use` 前缀 + camelCase | `useUserList()`, `usePagination()` |
| 常量 | UPPER_SNAKE_CASE | `const MAX_FILE_SIZE = 5 * 1024 * 1024` |
| 类型/接口 | PascalCase | `interface UserInfo {}`, `type PageParams = {}` |

### Props 和 Emits 定义

```vue
<script setup lang="ts">
// Props — 使用 TypeScript 类型声明
interface Props {
  userId: number
  userName?: string
  readonly?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  userName: '',
  readonly: false,
})

// Emits — 使用 TypeScript 类型声明
interface Emits {
  (e: 'update-user', user: UserInfo): void
  (e: 'delete', id: number): void
}

const emit = defineEmits<Emits>()
</script>
```

## 状态管理

### Pinia Store 规范

```typescript
// stores/user.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { getUserList, getUserDetail } from '@/api/user'
import type { UserInfo, UserQuery } from '@/types/user'

export const useUserStore = defineStore('user', () => {
  // state
  const users = ref<UserInfo[]>([])
  const currentUser = ref<UserInfo | null>(null)
  const loading = ref(false)

  // getters
  const activeUsers = computed(() => users.value.filter(u => u.status === 1))

  // actions
  async function fetchUsers(query?: UserQuery) {
    loading.value = true
    try {
      const { data } = await getUserList(query)
      users.value = data.records
    } finally {
      loading.value = false
    }
  }

  function resetState() {
    users.value = []
    currentUser.value = null
  }

  return { users, currentUser, loading, activeUsers, fetchUsers, resetState }
})
```

### 状态管理规则

- 使用 **Setup Store 语法**（函数式），不使用 Option Store
- 每个业务模块一个独立 Store 文件
- 组件中**禁止直接修改 props**，通过 `emit` 通知父组件
- 跨组件共享的状态放 Pinia Store，组件内部状态使用 `ref` / `reactive`
- Store 中的异步操作必须处理 loading 和 error 状态
- 离开页面时调用 `resetState()` 清理状态（防止数据残留）

## API 集成

### 统一 request 封装

```typescript
// utils/request.ts
import axios from 'axios'
import type { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import router from '@/router'

const service: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  timeout: 15000,
})

// 请求拦截器
service.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error),
)

// 响应拦截器
service.interceptors.response.use(
  (response: AxiosResponse) => {
    const { code, message, data } = response.data
    if (code === 200) {
      return data
    }
    // 业务错误
    ElMessage.error(message || '请求失败')
    return Promise.reject(new Error(message))
  },
  (error) => {
    if (error.response?.status === 401) {
      ElMessage.error('登录已过期，请重新登录')
      router.push('/login')
    } else {
      ElMessage.error(error.message || '网络错误')
    }
    return Promise.reject(error)
  },
)

export default service
```

### API 模块化组织

```typescript
// api/user.ts
import request from '@/utils/request'
import type { UserInfo, UserQuery, UserCreateDTO } from '@/types/user'
import type { PageResult } from '@/types/common'

/** 获取用户列表 */
export function getUserList(params?: UserQuery) {
  return request.get<PageResult<UserInfo>>('/api/v1/users', { params })
}

/** 获取用户详情 */
export function getUserDetail(id: number) {
  return request.get<UserInfo>(`/api/v1/users/${id}`)
}

/** 创建用户 */
export function createUser(data: UserCreateDTO) {
  return request.post<UserInfo>('/api/v1/users', data)
}

/** 删除用户 */
export function deleteUser(id: number) {
  return request.delete(`/api/v1/users/${id}`)
}
```

### API 调用规则

- 所有 API 调用统一通过封装的 `request` 模块，禁止直接 `import axios`
- 每个后端模块对应一个 `api/*.ts` 文件
- 每个接口函数都要有 JSDoc 注释说明用途
- 请求/响应数据必须有 TypeScript 类型定义
- 错误由响应拦截器统一处理，组件中无需重复 catch

## 路由

### 路由懒加载

```typescript
// router/index.ts
import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/LoginPage.vue'),
    meta: { requiresAuth: false },
  },
  {
    path: '/',
    component: () => import('@/layouts/DefaultLayout.vue'),
    children: [
      {
        path: 'users',
        name: 'UserList',
        component: () => import('@/views/user/UserList.vue'),
        meta: { requiresAuth: true, title: '用户管理' },
      },
      {
        path: 'users/:id',
        name: 'UserDetail',
        component: () => import('@/views/user/UserDetail.vue'),
        meta: { requiresAuth: true, title: '用户详情' },
      },
    ],
  },
]
```

### 路由守卫 + 权限控制

```typescript
// router/guard.ts
import router from './index'
import { useUserStore } from '@/stores/user'

router.beforeEach(async (to, from, next) => {
  const token = localStorage.getItem('token')

  if (to.meta.requiresAuth === false) {
    next()
    return
  }

  if (!token) {
    next({ path: '/login', query: { redirect: to.fullPath } })
    return
  }

  const userStore = useUserStore()
  if (!userStore.currentUser) {
    try {
      await userStore.fetchCurrentUser()
    } catch {
      localStorage.removeItem('token')
      next('/login')
      return
    }
  }

  next()
})
```

### 路由规则

- 所有页面路由必须使用**懒加载** `() => import()`
- 路由 `meta` 中声明 `requiresAuth`（是否需要登录）和 `title`（页面标题）
- 路由守卫中统一处理认证检查和权限校验
- 404 页面使用 `path: '/:pathMatch(.*)*'` 兜底

## 样式

### Scoped CSS

```vue
<style scoped lang="scss">
.user-list {
  padding: 20px;

  &__header {
    display: flex;
    justify-content: space-between;
    margin-bottom: 16px;
  }

  &__table {
    width: 100%;
  }
}
</style>
```

### 样式规则

- 组件样式必须使用 `scoped`，防止全局污染
- 全局样式放在 `styles/` 目录，通过 `main.ts` 引入
- 主题色、间距、字号等使用 **CSS 变量**，便于统一调整
- Element Plus 主题定制通过 SCSS 变量覆盖或 CSS 变量

### CSS 变量示例

```scss
// styles/variables.scss
:root {
  --color-primary: #409eff;
  --color-success: #67c23a;
  --color-warning: #e6a23c;
  --color-danger: #f56c6c;

  --font-size-sm: 12px;
  --font-size-base: 14px;
  --font-size-lg: 16px;

  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
}
```

### Element Plus 定制

```scss
// styles/element-plus.scss
@forward 'element-plus/theme-chalk/src/common/var.scss' with (
  $colors: (
    'primary': (
      'base': #409eff,
    ),
  ),
);
```

## 测试

### 组件测试（Vitest + Vue Test Utils）

```typescript
// components/__tests__/UserList.test.ts
import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createTestingPinia } from '@pinia/testing'
import UserList from '../UserList.vue'
import { useUserStore } from '@/stores/user'

describe('UserList', () => {
  it('渲染用户列表', async () => {
    const wrapper = mount(UserList, {
      global: {
        plugins: [
          createTestingPinia({
            initialState: {
              user: {
                users: [
                  { id: 1, userName: '张三', email: 'zhangsan@example.com' },
                  { id: 2, userName: '李四', email: 'lisi@example.com' },
                ],
              },
            },
          }),
        ],
      },
    })

    expect(wrapper.text()).toContain('张三')
    expect(wrapper.text()).toContain('李四')
  })

  it('点击删除按钮触发确认弹窗', async () => {
    const wrapper = mount(UserList, {
      global: {
        plugins: [createTestingPinia()],
      },
    })

    await wrapper.find('.btn-delete').trigger('click')
    expect(wrapper.emitted('delete')).toBeTruthy()
  })
})
```

### 测试规则

- 通用组件和核心业务组件必须有测试
- 使用 `createTestingPinia` Mock Pinia Store
- 测试用例覆盖：正常渲染、用户交互、异常状态、空状态
- 测试文件放在组件同级的 `__tests__/` 目录下
- 测试命名：`{ComponentName}.test.ts`

### Composable 测试

```typescript
// composables/__tests__/usePagination.test.ts
import { describe, it, expect } from 'vitest'
import { usePagination } from '../usePagination'

describe('usePagination', () => {
  it('初始化默认分页参数', () => {
    const { page, size, total } = usePagination()
    expect(page.value).toBe(1)
    expect(size.value).toBe(20)
    expect(total.value).toBe(0)
  })

  it('切换页码', () => {
    const { page, handlePageChange } = usePagination()
    handlePageChange(3)
    expect(page.value).toBe(3)
  })
})
```

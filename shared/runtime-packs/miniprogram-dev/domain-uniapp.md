# Miniprogram Domain — uni-app (Vue 3, Conditional Compilation, easycom)

## 1. Conditional Compilation

```vue
<!-- pages/index/index.vue -->
<template>
  <view class="container">
    <!-- #ifdef MP-WEIXIN -->
    <button open-type="getPhoneNumber" @getphonenumber="onGetPhoneNumber">
      WeChat Phone Login
    </button>
    <!-- #endif -->

    <!-- #ifdef H5 -->
    <button @click="h5Login">H5 Login</button>
    <!-- #endif -->

    <!-- #ifdef APP-PLUS -->
    <button @click="appLogin">App Login</button>
    <!-- #endif -->
  </view>
</template>

<script setup>
import { ref } from 'vue';

const userInfo = ref(null);

// #ifdef MP-WEIXIN
const onGetPhoneNumber = (e) => {
  if (e.detail.errMsg === 'getPhoneNumber:ok') {
    // Send encryptedData and iv to backend
    uni.request({
      url: 'https://api.example.com/auth/phone',
      method: 'POST',
      data: {
        encryptedData: e.detail.encryptedData,
        iv: e.detail.iv,
        code: loginCode.value
      }
    });
  }
};
// #endif

// #ifdef H5
const h5Login = () => {
  // H5-specific login (OAuth, SMS, etc.)
};
// #endif

// #ifdef APP-PLUS
const appLogin = () => {
  uni.login({
    provider: 'weixin',
    success: (res) => {
      console.log('App login success:', res);
    }
  });
};
// #endif
</script>
```

## 2. pages.json Configuration

```json
{
  "pages": [
    {
      "path": "pages/index/index",
      "style": {
        "navigationBarTitleText": "Home"
      }
    }
  ],
  "subPackages": [
    {
      "root": "pkgs/order",
      "pages": [
        { "path": "pages/order-list", "style": { "navigationBarTitleText": "Orders" } },
        { "path": "pages/order-detail", "style": { "navigationBarTitleText": "Order Detail" } }
      ]
    }
  ],
  "tabBar": {
    "list": [
      { "pagePath": "pages/index/index", "text": "Home" },
      { "pagePath": "pages/profile/profile", "text": "Profile" }
    ]
  },
  "globalStyle": {
    "navigationBarTextStyle": "black",
    "navigationBarBackgroundColor": "#F8F8F8"
  },
  "easycom": {
    "autoscan": true,
    "custom": {
      "^u--(.*)": "uview-plus/components/u-$1/u-$1.vue",
      "^my-(.*)": "@/components/my-$1/my-$1.vue"
    }
  }
}
```

## 3. Vue 3 Composition API in uni-app

```vue
<!-- components/product-list/product-list.vue -->
<template>
  <view class="product-list">
    <view v-if="loading" class="loading">
      <text>Loading...</text>
    </view>
    <view v-else-if="products.length === 0" class="empty">
      <text>No products found</text>
    </view>
    <view v-else class="list">
      <product-card
        v-for="product in products"
        :key="product.id"
        :product="product"
        @select="onSelect"
      />
    </view>
    <view v-if="hasMore" class="load-more" @click="loadMore">
      <text>Load More</text>
    </view>
  </view>
</template>

<script setup>
import { ref, onMounted } from 'vue';

const props = defineProps({
  categoryId: {
    type: String,
    default: ''
  }
});

const emit = defineEmits(['productSelect']);

const products = ref([]);
const loading = ref(false);
const hasMore = ref(true);
const page = ref(1);

const fetchProducts = async () => {
  loading.value = true;
  try {
    const res = await uni.request({
      url: 'https://api.example.com/products',
      data: {
        categoryId: props.categoryId,
        page: page.value,
        limit: 20
      }
    });
    
    if (page.value === 1) {
      products.value = res.data.items;
    } else {
      products.value.push(...res.data.items);
    }
    
    hasMore.value = res.data.items.length === 20;
    page.value++;
  } finally {
    loading.value = false;
  }
};

const loadMore = () => {
  if (!loading.value && hasMore.value) {
    fetchProducts();
  }
};

const onSelect = (product) => {
  emit('productSelect', product);
};

onMounted(() => {
  fetchProducts();
});

// Expose for parent
defineExpose({
  refresh: () => {
    page.value = 1;
    return fetchProducts();
  }
});
</script>

<style scoped>
.product-list {
  padding: 16rpx;
}

.loading, .empty {
  text-align: center;
  padding: 40rpx;
  color: #999;
}

.load-more {
  text-align: center;
  padding: 20rpx;
  color: #007AFF;
}
</style>
```

## 4. easycom Auto Component Registration

```vue
<!-- pages/index/index.vue -->
<!-- No import needed! easycom auto-discovers components -->
<template>
  <view>
    <!-- components/my-header/my-header.vue auto-registered -->
    <my-header title="Home" />
    
    <!-- components/my-product-card/my-product-card.vue auto-registered -->
    <my-product-card
      v-for="item in products"
      :key="item.id"
      :product="item"
    />
  </view>
</template>
```

## 5. Cross-Platform Debugging Tips

```javascript
// Platform detection helpers
const isWeixin = () => {
  // #ifdef MP-WEIXIN
  return true;
  // #endif
  return false;
};

// Safe API usage
const safeRequest = (options) => {
  // #ifdef MP-WEIXIN
  return wx.request(options);
  // #endif
  
  // #ifdef H5
  return fetch(options.url, {
    method: options.method || 'GET',
    headers: options.header,
    body: options.data ? JSON.stringify(options.data) : undefined
  });
  // #endif
  
  // #ifdef APP-PLUS
  return uni.request(options);
  // #endif
};
```

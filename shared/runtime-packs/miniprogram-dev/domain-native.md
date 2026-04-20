# Miniprogram Domain — Native WeChat Miniprogram (WXML/WXSS/JS, app.js Lifecycle, wx.* APIs)

## 1. Component and Page System

### 1.1 Component Constructor

```javascript
// components/product-card/product-card.js
Component({
  // External properties interface
  properties: {
    product: {
      type: Object,
      value: {},
      observer(newVal, oldVal) {
        console.log('Product changed:', newVal);
      }
    },
    showPrice: {
      type: Boolean,
      value: true
    }
  },

  // Internal data
  data: {
    isLoading: false,
    formattedPrice: ''
  },

  // Lifecycle
  lifetimes: {
    created() {
      console.log('Component created');
    },
    attached() {
      this._formatPrice();
    },
    ready() {
      console.log('Component ready');
    },
    detached() {
      console.log('Component detached');
    }
  },

  // Page lifecycle (when component is in a page)
  pageLifetimes: {
    show() {
      // Page shown
    },
    hide() {
      // Page hidden
    },
    resize(size) {
      // Page resized
    }
  },

  // Methods
  methods: {
    onTap() {
      this.triggerEvent('select', { productId: this.data.product.id });
    },

    _formatPrice() {
      const price = this.data.product.price;
      this.setData({
        formattedPrice: `¥${(price / 100).toFixed(2)}`
      });
    }
  },

  // Observers for deep path watching
  observers: {
    'product.price': function(price) {
      this._formatPrice();
    }
  }
});
```

```xml
<!-- components/product-card/product-card.wxml -->
<view class="product-card" bindtap="onTap">
  <image class="product-image" src="{{product.imageUrl}}" mode="aspectFill" lazy-load />
  <view class="product-info">
    <text class="product-name">{{product.name}}</text>
    <text class="product-price" wx:if="{{showPrice}}">{{formattedPrice}}</text>
  </view>
</view>
```

```css
/* components/product-card/product-card.wxss */
.product-card {
  display: flex;
  padding: 16rpx;
  background: #fff;
  border-radius: 12rpx;
  margin-bottom: 16rpx;
}

.product-image {
  width: 200rpx;
  height: 200rpx;
  border-radius: 8rpx;
}

.product-info {
  flex: 1;
  margin-left: 16rpx;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.product-name {
  font-size: 28rpx;
  color: #333;
  line-height: 1.4;
}

.product-price {
  font-size: 32rpx;
  color: #ff4444;
  font-weight: bold;
}
```

### 1.2 WXML Template System

```xml
<!-- pages/product-list/product-list.wxml -->
<view class="container">
  <!-- Conditional render -->
  <view wx:if="{{isLoading}}" class="loading">
    <view class="skeleton" wx:for="{{3}}" wx:key="*this"></view>
  </view>

  <!-- Empty state -->
  <view wx:elif="{{products.length === 0}}" class="empty">
    <image src="/assets/empty.png" mode="aspectFit" />
    <text>No products found</text>
  </view>

  <!-- List with key -->
  <view wx:else class="product-list">
    <product-card
      wx:for="{{products}}"
      wx:key="id"
      wx:for-item="product"
      wx:for-index="index"
      product="{{product}}"
      show-price="{{true}}"
      bind:select="onProductSelect"
    />
  </view>

  <!-- Hidden vs wx:if -->
  <!-- Use hidden for frequent toggle (display:none) -->
  <view hidden="{{!showFilter}}" class="filter-panel">
    <!-- Filter content -->
  </view>
</view>
```

### 1.3 WXS Performance Pattern

```javascript
// utils/filter.wxs
var format = {
  price: function(p) {
    return '¥' + (p / 100).toFixed(2);
  },
  date: function(timestamp) {
    var date = getDate(timestamp);
    return [date.getFullYear(), date.getMonth() + 1, date.getDate()].join('-');
  }
};

module.exports = format;
```

```xml
<!-- pages/order-list/order-list.wxml -->
<wxs src="../../utils/filter.wxs" module="filter" />

<view class="order-item" wx:for="{{orders}}" wx:key="id">
  <text class="order-price">{{filter.price(item.totalAmount)}}</text>
  <text class="order-date">{{filter.date(item.createdAt)}}</text>
</view>
```

---

## 2. Page Routing and Navigation

```javascript
// app.js — App lifecycle
App({
  globalData: {
    userInfo: null,
    systemInfo: null
  },

  onLaunch(options) {
    console.log('App launched', options);
    this._initSystemInfo();
    this._checkUpdate();
  },

  onShow(options) {
    console.log('App shown', options);
  },

  onHide() {
    console.log('App hidden');
  },

  onError(error) {
    console.error('App error:', error);
  },

  _initSystemInfo() {
    wx.getSystemInfo({
      success: (res) => {
        this.globalData.systemInfo = res;
      }
    });
  },

  _checkUpdate() {
    const updateManager = wx.getUpdateManager();
    updateManager.onUpdateReady(() => {
      wx.showModal({
        title: 'Update Available',
        content: 'A new version is ready. Restart to apply?',
        success: (res) => {
          if (res.confirm) updateManager.applyUpdate();
        }
      });
    });
  }
});
```

```javascript
// pages/product-list/product-list.js
Page({
  data: {
    products: [],
    isLoading: false,
    hasMore: true,
    page: 1
  },

  onLoad(options) {
    console.log('Page loaded with options:', options);
    this.loadProducts();
  },

  onShow() {
    // Page shown (after navigateBack or switchTab)
  },

  onReady() {
    // Page rendered for the first time
  },

  onHide() {
    // Page hidden
  },

  onUnload() {
    // Page destroyed — clean up timers, listeners
    if (this.data.pollTimer) {
      clearInterval(this.data.pollTimer);
    }
  },

  onPullDownRefresh() {
    this.setData({ page: 1, products: [] });
    this.loadProducts().then(() => {
      wx.stopPullDownRefresh();
    });
  },

  onReachBottom() {
    if (this.data.hasMore && !this.data.isLoading) {
      this.loadProducts();
    }
  },

  onShareAppMessage() {
    return {
      title: 'Check out these products!',
      path: '/pages/product-list/product-list'
    };
  },

  loadProducts() {
    this.setData({ isLoading: true });
    return wx.request({
      url: 'https://api.example.com/products',
      data: { page: this.data.page, limit: 20 }
    }).then(res => {
      const newProducts = [...this.data.products, ...res.data.items];
      this.setData({
        products: newProducts,
        page: this.data.page + 1,
        hasMore: res.data.items.length === 20,
        isLoading: false
      });
    });
  },

  onProductSelect(e) {
    const productId = e.detail.productId;
    wx.navigateTo({
      url: `/pages/product-detail/product-detail?id=${productId}`
    });
  }
});
```

---

## 3. app.json Configuration

```json
{
  "pages": [
    "pages/index/index",
    "pages/profile/profile"
  ],
  "subPackages": [
    {
      "root": "pkgs/order",
      "pages": [
        "pages/order-list",
        "pages/order-detail",
        "pages/payment-result"
      ]
    },
    {
      "root": "pkgs/product",
      "pages": [
        "pages/product-list",
        "pages/product-detail",
        "pages/product-search"
      ]
    }
  ],
  "preloadRule": {
    "pages/index/index": {
      "network": "all",
      "packages": ["pkgs/product"]
    }
  },
  "tabBar": {
    "color": "#999999",
    "selectedColor": "#ff4444",
    "backgroundColor": "#ffffff",
    "borderStyle": "black",
    "list": [
      {
        "pagePath": "pages/index/index",
        "text": "Home",
        "iconPath": "assets/tab-home.png",
        "selectedIconPath": "assets/tab-home-active.png"
      },
      {
        "pagePath": "pages/profile/profile",
        "text": "Profile",
        "iconPath": "assets/tab-profile.png",
        "selectedIconPath": "assets/tab-profile-active.png"
      }
    ]
  },
  "window": {
    "backgroundTextStyle": "dark",
    "navigationBarBackgroundColor": "#fff",
    "navigationBarTitleText": "My App",
    "navigationBarTextStyle": "black",
    "enablePullDownRefresh": true
  },
  "permission": {
    "scope.userLocation": {
      "desc": "Your location is used to find nearby stores"
    }
  },
  "requiredBackgroundModes": ["audio"],
  "lazyCodeLoading": "requiredComponents"
}
```

---

## 4. setData Performance Model

```javascript
// BAD — full state serialization
Page({
  data: {
    user: { name: 'John', age: 30 },
    items: [{ id: 1, name: 'A' }, { id: 2, name: 'B' }],
    loading: false
  },

  updateItem(index, newName) {
    const items = this.data.items;
    items[index].name = newName;
    this.setData({ items }); // Serializes ALL items!
  }
});

// GOOD — diff-only path
Page({
  data: {
    items: [{ id: 1, name: 'A' }, { id: 2, name: 'B' }]
  },

  updateItem(index, newName) {
    this.setData({
      [`items[${index}].name`]: newName
    }); // Only one field crosses IPC boundary
  }
});

// GOOD — batch multiple changes
Page({
  data: {
    list: [],
    page: 1,
    hasMore: true
  },

  onLoadMore() {
    fetchMore().then(res => {
      const updates = {};
      res.items.forEach((item, index) => {
        const dataIndex = this.data.list.length + index;
        updates[`list[${dataIndex}]`] = item;
      });
      updates.page = this.data.page + 1;
      updates.hasMore = res.items.length === 20;
      this.setData(updates); // Single IPC call with multiple changes
    });
  }
});
```

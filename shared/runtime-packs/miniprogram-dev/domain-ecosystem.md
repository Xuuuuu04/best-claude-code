# Miniprogram Domain — WeChat Ecosystem (Login, Payment, Cloud Functions)

## 1. Login Chain (wx.login → code2session → JWT)

```javascript
// services/auth.js
class AuthService {
  static async login() {
    try {
      // 1. Get code from WeChat
      const loginRes = await wx.login();
      
      // 2. Send code to own backend
      const backendRes = await wx.request({
        url: 'https://api.ourservice.com/auth/wechat-login',
        method: 'POST',
        data: { code: loginRes.code }
      });
      
      // 3. Backend calls code2session, stores session_key, returns JWT
      const { token, expiresAt } = backendRes.data;
      
      // 4. Store own-service token ONLY
      wx.setStorageSync('token', token);
      wx.setStorageSync('token_expires', expiresAt);
      
      return token;
    } catch (error) {
      console.error('Login failed:', error);
      throw error;
    }
  }

  static async checkSession() {
    try {
      await wx.checkSession();
      return true;
    } catch {
      // Session expired, re-login
      return this.login();
    }
  }

  static getToken() {
    return wx.getStorageSync('token');
  }

  static isLoggedIn() {
    const token = this.getToken();
    const expiresAt = wx.getStorageSync('token_expires');
    return token && Date.now() < expiresAt;
  }
}
```

## 2. Payment Integration (wx.requestPayment)

```javascript
// services/payment.js
class PaymentService {
  static async createOrder(productId) {
    const token = AuthService.getToken();
    const res = await wx.request({
      url: 'https://api.ourservice.com/orders/create',
      method: 'POST',
      header: { Authorization: `Bearer ${token}` },
      data: { productId }
    });
    return res.data; // { orderId, prepayId, nonceStr, timeStamp, sign }
  }

  static async requestPayment(orderData) {
    return new Promise((resolve, reject) => {
      wx.requestPayment({
        timeStamp: orderData.timeStamp,
        nonceStr: orderData.nonceStr,
        package: `prepay_id=${orderData.prepayId}`,
        signType: 'RSA',
        paySign: orderData.sign,
        success: () => {
          // Success = UI flow complete, NOT payment confirmed
          resolve({ status: 'processing' });
        },
        fail: (err) => {
          reject(err);
        }
      });
    });
  }

  static async pollOrderStatus(orderId, maxAttempts = 15) {
    const token = AuthService.getToken();
    
    for (let i = 0; i < maxAttempts; i++) {
      await new Promise(r => setTimeout(r, 2000));
      
      const res = await wx.request({
        url: `https://api.ourservice.com/orders/${orderId}/status`,
        header: { Authorization: `Bearer ${token}` }
      });
      
      if (res.data.status === 'PAID') {
        return { status: 'paid', order: res.data };
      }
    }
    
    return { status: 'timeout' };
  }
}

// Page usage
Page({
  data: {
    paymentStatus: 'idle', // idle | processing | paid | failed
    orderId: null
  },

  async onPayNow() {
    try {
      // 1. Create order on backend
      const orderData = await PaymentService.createOrder(this.data.productId);
      
      // 2. Call wx.requestPayment
      this.setData({ paymentStatus: 'processing' });
      await PaymentService.requestPayment(orderData);
      
      // 3. Poll backend for actual confirmation
      const result = await PaymentService.pollOrderStatus(orderData.orderId);
      
      if (result.status === 'paid') {
        this.setData({ paymentStatus: 'paid' });
        wx.navigateTo({ url: '/pages/success/success' });
      } else {
        this.setData({ paymentStatus: 'timeout' });
      }
    } catch (error) {
      this.setData({ paymentStatus: 'failed' });
      wx.showToast({ title: 'Payment failed', icon: 'none' });
    }
  }
});
```

## 3. Cloud Functions

```javascript
// cloudfunctions/login/index.js
const cloud = require('wx-server-sdk');
cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });

exports.main = async (event, context) => {
  const { code } = event;
  const wxContext = cloud.getWXContext();
  
  try {
    // 1. Call code2session
    const res = await cloud.openapi.auth.code2Session({
      jsCode: code,
      grantType: 'authorization_code'
    });
    
    const { openid, session_key, unionid } = res;
    
    // 2. Store or update user
    const db = cloud.database();
    const userCollection = db.collection('users');
    
    const existingUser = await userCollection.where({ openid }).get();
    
    if (existingUser.data.length === 0) {
      await userCollection.add({
        data: {
          openid,
          unionid: unionid || '',
          createdAt: db.serverDate(),
          lastLoginAt: db.serverDate()
        }
      });
    } else {
      await userCollection.doc(existingUser.data[0]._id).update({
        data: { lastLoginAt: db.serverDate() }
      });
    }
    
    // 3. Return own-service token (never return session_key!)
    return {
      success: true,
      token: generateJWT(openid), // Your JWT generation
      expiresAt: Date.now() + 7 * 24 * 60 * 60 * 1000
    };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

function generateJWT(openid) {
  // JWT generation logic
  return 'jwt_token_here';
}
```

## 4. Cloud Database Security Rules

```json
{
  "read": "doc._openid == auth.openid",
  "write": "doc._openid == auth.openid"
}
```

```javascript
// cloudfunctions/getOrders/index.js
const cloud = require('wx-server-sdk');
cloud.init();

exports.main = async (event, context) => {
  const wxContext = cloud.getWXContext();
  const db = cloud.database();
  
  // Security: only return orders belonging to current user
  const orders = await db.collection('orders')
    .where({ _openid: wxContext.OPENID })
    .orderBy('createdAt', 'desc')
    .get();
  
  return { success: true, data: orders.data };
};
```

## 5. Privacy Consent Popup

```javascript
// components/privacy-popup/privacy-popup.js
Component({
  properties: {
    visible: { type: Boolean, value: false }
  },

  methods: {
    onAgree() {
      wx.setStorageSync('privacy_agreed', true);
      wx.setStorageSync('privacy_agreed_at', Date.now());
      this.triggerEvent('agree');
    },

    onDisagree() {
      this.triggerEvent('disagree');
    },

    onOpenPrivacyContract() {
      wx.openPrivacyContract({
        success: () => console.log('Privacy contract opened'),
        fail: () => wx.showToast({ title: 'Failed to open', icon: 'none' })
      });
    }
  }
});
```

```xml
<!-- components/privacy-popup/privacy-popup.wxml -->
<view class="privacy-popup" wx:if="{{visible}}">
  <view class="privacy-mask"></view>
  <view class="privacy-content">
    <text class="privacy-title">Privacy Agreement</text>
    <text class="privacy-text">
      Before using this miniprogram, please read and agree to our 
      <text class="privacy-link" bindtap="onOpenPrivacyContract">Privacy Policy</text>.
    </text>
    <view class="privacy-actions">
      <button class="btn-disagree" bindtap="onDisagree">Disagree</button>
      <button class="btn-agree" bindtap="onAgree">Agree</button>
    </view>
  </view>
</view>
```

```javascript
// app.js — show privacy popup before data collection
App({
  onLaunch() {
    this._checkPrivacyAgreement();
  },

  _checkPrivacyAgreement() {
    const agreed = wx.getStorageSync('privacy_agreed');
    if (!agreed) {
      // Show privacy popup on first launch
      this.globalData.showPrivacyPopup = true;
    }
  }
});
```

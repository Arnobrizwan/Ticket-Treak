# Flutter Stripe ProGuard rules (for release builds)
# This keeps classes and members used via reflection or dynamic loading by the Stripe SDK and its React Native wrapper.

# General rules for the core Stripe Android SDK
-keep class com.stripe.** { *; }
-keep class com.google.android.gms.wallet.** { *; }
-keep class com.google.android.gms.identity.** { *; }
-keep class com.mastercard.android.rpac.** { *; }
-keep class com.visa.android.embedded.* { *; }
-keep class org.bouncycastle.asn1.** { *; }
-keep class org.bouncycastle.jcajce.** { *; }
-keep class org.bouncycastle.jce.** { *; }
-keep class org.bouncycastle.math.ec.** { *; }
-keep class org.bouncycastle.util.** { *; }

# For GMS/Wallet integration (if using Google Pay)
-keep class com.google.android.gms.internal.wallet.* { *; }
-dontwarn com.google.android.gms.**

# For Push Provisioning - Crucial for your current error!
-keep class com.stripe.android.pushProvisioning.** { *; }
# Also explicitly keep the React Native wrapper classes for push provisioning
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }

# Required for some AndroidX dependencies
-keep class androidx.lifecycle.DefaultLifecycleObserver { *; }
-keep class androidx.lifecycle.FullLifecycleObserver { *; }
-keep class androidx.lifecycle.LifecycleObserver { *; }
-keep class androidx.lifecycle.OnLifecycleEvent { *; }

# General rules for React Native bridge components often needed by Flutter wrappers
-keep class com.facebook.react.bridge.** { *; }
-keep class com.facebook.react.uimanager.** { *; }
-keep class com.facebook.react.views.** { *; }
-keep class com.facebook.react.modules.** { *; }
-keep class com.facebook.react.shell.** { *; }
-keep class com.facebook.react.animation.** { *; }

# Specific to react-native-stripe
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**
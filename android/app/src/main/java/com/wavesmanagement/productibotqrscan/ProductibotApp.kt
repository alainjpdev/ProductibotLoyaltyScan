package com.wavesmanagement.productibotqrscan

import android.app.Application
import com.wavesmanagement.productibotqrscan.data.SupabaseManager

class ProductibotApp : Application() {
    override fun onCreate() {
        super.onCreate()
        SupabaseManager.initialize(applicationContext)
    }
}

package com.wavesmanagement.productibotqrscan.data.model

import kotlinx.serialization.Serializable
import java.util.UUID

enum class ScanResultType {
    VISIT,
    REWARD,
    ERROR
}

data class ScanProcessResult(
    val id: String = UUID.randomUUID().toString(),
    val type: ScanResultType,
    val title: String,
    val subtitle: String,
    val clientName: String? = null,
    val detail: String? = null,
    val isCycleUnlocked: Boolean = false,
    val timestamp: Long = System.currentTimeMillis()
)

@Serializable
data class StaffProfile(
    val store_id: String? = null,
    val full_name: String? = null,
    val role: String? = null
)

@Serializable
data class StoreProfile(
    val name: String? = null,
    val logo_url: String? = null
)

@Serializable
data class CouponRecord(
    val id: String,
    val profile_id: String,
    val store_id: String? = null,
    val reward_description: String,
    val status: String
)

@Serializable
data class UpdateCouponPayload(
    val status: String,
    val redeemed_at: String,
    val redeemed_by: String? = null
)

@Serializable
data class ProfileRecord(
    val id: String,
    val full_name: String? = null,
    val email: String? = null
)

@Serializable
data class IncrementVisitsParams(
    val p_profile_id: String,
    val p_store_id: String,
    val p_amount: Int = 1
)

@Serializable
data class IncrementVisitsResponse(
    val success: Boolean? = null,
    val loyalty_type: String? = null,
    val visits: Int? = null,
    val stamps_current: Int? = null,
    val stamp_target: Int? = null,
    val stamp_cycles_completed: Int? = null,
    val cycle_unlocked: Boolean? = null,
    val reward_title: String? = null
)

@Serializable
data class InsertTxPayload(
    val store_id: String,
    val profile_id: String,
    val visits_change: Int,
    val description: String,
    val staff_id: String? = null
)

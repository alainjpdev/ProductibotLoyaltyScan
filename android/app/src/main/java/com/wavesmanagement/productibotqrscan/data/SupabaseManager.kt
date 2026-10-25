package com.wavesmanagement.productibotqrscan.data

import android.content.Context
import android.util.Log
import com.wavesmanagement.productibotqrscan.config.Configuration
import com.wavesmanagement.productibotqrscan.data.model.*
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.status.SessionStatus
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.text.SimpleDateFormat
import java.util.*
import java.util.regex.Pattern

class SupabaseManager private constructor(context: Context) {

    val client: SupabaseClient = createSupabaseClient(
        supabaseUrl = Configuration.SUPABASE_URL,
        supabaseKey = Configuration.SUPABASE_ANON_KEY
    ) {
        install(Auth)
        install(Postgrest)
    }

    private val scope = CoroutineScope(Dispatchers.IO)

    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private val _storeId = MutableStateFlow<String?>(null)
    val storeId: StateFlow<String?> = _storeId.asStateFlow()

    private val _storeName = MutableStateFlow<String?>("Productibot Loyalty")
    val storeName: StateFlow<String?> = _storeName.asStateFlow()

    private val _storeLogoUrl = MutableStateFlow<String?>(null)
    val storeLogoUrl: StateFlow<String?> = _storeLogoUrl.asStateFlow()

    private val _staffId = MutableStateFlow<String?>(null)
    val staffId: StateFlow<String?> = _staffId.asStateFlow()

    private val _staffName = MutableStateFlow<String?>(null)
    val staffName: StateFlow<String?> = _staffName.asStateFlow()

    private val _staffRole = MutableStateFlow<String?>(null)
    val staffRole: StateFlow<String?> = _staffRole.asStateFlow()

    private val _lastScanResult = MutableStateFlow<ScanProcessResult?>(null)
    val lastScanResult: StateFlow<ScanProcessResult?> = _lastScanResult.asStateFlow()

    init {
        scope.launch {
            client.auth.sessionStatus.collect { status ->
                when (status) {
                    is SessionStatus.Authenticated -> {
                        _isAuthenticated.value = true
                        fetchStoreDetails()
                    }
                    is SessionStatus.NotAuthenticated -> {
                        _isAuthenticated.value = false
                        clearState()
                    }
                    else -> {}
                }
            }
        }
    }

    private fun clearState() {
        _storeId.value = null
        _storeName.value = null
        _storeLogoUrl.value = null
        _staffId.value = null
        _staffName.value = null
        _staffRole.value = null
        _lastScanResult.value = null
    }

    suspend fun signIn(email: String, pass: String) {
        client.auth.signInWith(Email) {
            this.email = email.trim()
            this.password = pass
        }
    }

    suspend fun signOut() {
        client.auth.signOut()
        clearState()
    }

    suspend fun fetchStoreDetails() {
        try {
            val session = client.auth.currentSessionOrNull() ?: return
            val userId = session.user?.id ?: return

            val staffList = try {
                client.postgrest["staff_profiles"]
                    .select(Columns.list("store_id", "full_name", "role")) {
                        filter {
                            eq("id", userId)
                        }
                        limit(1)
                    }.decodeList<StaffProfile>()
            } catch (e: Exception) {
                Log.e("SupabaseManager", "Error querying staff_profiles: ${e.message}")
                emptyList()
            }

            val staff = staffList.firstOrNull()
            val targetStoreId = staff?.store_id ?: Configuration.DEFAULT_STORE_ID

            val storeList = try {
                client.postgrest["stores"]
                    .select(Columns.list("name", "logo_url")) {
                        filter {
                            eq("id", targetStoreId)
                        }
                        limit(1)
                    }.decodeList<StoreProfile>()
            } catch (e: Exception) {
                Log.e("SupabaseManager", "Error querying stores: ${e.message}")
                emptyList()
            }

            val store = storeList.firstOrNull()

            _staffId.value = userId
            _staffName.value = staff?.full_name
            _staffRole.value = staff?.role
            _storeId.value = targetStoreId
            _storeName.value = store?.name ?: "Productibot Loyalty"
            _storeLogoUrl.value = store?.logo_url
        } catch (e: Exception) {
            Log.e("SupabaseManager", "Error fetching store details", e)
        }
    }

    suspend fun processScannedCode(rawCode: String): ScanProcessResult {
        val uuid = extractUUID(rawCode) ?: return ScanProcessResult(
            type = ScanResultType.ERROR,
            title = "Código No Válido",
            subtitle = "El formato del QR no corresponde a un ID reconocido."
        )

        val activeStoreId = _storeId.value ?: Configuration.DEFAULT_STORE_ID
        val currentStaffId = _staffId.value

        // 1. Verificar si es un Cupón de Premio (coupons)
        try {
            val coupons = client.postgrest["coupons"]
                .select(Columns.list("id", "profile_id", "store_id", "reward_description", "status")) {
                    filter {
                        eq("id", uuid)
                    }
                    limit(1)
                }.decodeList<CouponRecord>()

            if (coupons.isNotEmpty()) {
                val coupon = coupons.first()

                if (coupon.store_id != null && coupon.store_id != activeStoreId) {
                    return ScanProcessResult(
                        type = ScanResultType.ERROR,
                        title = "Sucursal Incorrecta",
                        subtitle = "Este cupón pertenece a otra sucursal y no puede canjearse aquí."
                    )
                }

                if (coupon.status.equals("redeemed", ignoreCase = true)) {
                    return ScanProcessResult(
                        type = ScanResultType.ERROR,
                        title = "Cupón Ya Canjeado",
                        subtitle = "Este cupón de premio ya fue canjeado con anterioridad."
                    )
                }

                // Canjear cupón
                val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
                sdf.timeZone = TimeZone.getTimeZone("UTC")
                val nowString = sdf.format(Date())

                client.postgrest["coupons"].update(
                    UpdateCouponPayload(
                        status = "redeemed",
                        redeemed_at = nowString,
                        redeemed_by = currentStaffId
                    )
                ) {
                    filter {
                        eq("id", coupon.id)
                    }
                }

                // Registrar transacción en el libro mayor
                val cleanReward = if (coupon.reward_description.startsWith("Promo:")) {
                    coupon.reward_description.replace("Promo: ", "").replace("Promo:", "").trim()
                } else {
                    coupon.reward_description
                }

                try {
                    client.postgrest["loyalty_transactions"].insert(
                        InsertTxPayload(
                            store_id = activeStoreId,
                            profile_id = coupon.profile_id,
                            visits_change = 0,
                            description = "Canje Premio: $cleanReward",
                            staff_id = currentStaffId
                        )
                    )
                } catch (e: Exception) {
                    Log.e("SupabaseManager", "Error insert transaction: ${e.message}")
                }

                // Obtener nombre del cliente
                val clientProf = try {
                    client.postgrest["profiles"]
                        .select(Columns.list("full_name", "email")) {
                            filter {
                                eq("id", coupon.profile_id)
                            }
                            limit(1)
                        }.decodeList<ProfileRecord>().firstOrNull()
                } catch (e: Exception) {
                    null
                }

                val clientName = clientProf?.full_name ?: clientProf?.email ?: "Cliente"

                val result = ScanProcessResult(
                    type = ScanResultType.REWARD,
                    title = "¡Premio Canjeado!",
                    subtitle = cleanReward,
                    clientName = clientName,
                    detail = "Premio canjeado con éxito y registrado en el historial.",
                    isCycleUnlocked = false
                )
                _lastScanResult.value = result
                return result
            }
        } catch (e: Exception) {
            Log.e("SupabaseManager", "Error al verificar cupón: ${e.message}")
        }

        // 2. Verificar si es un Perfil de Cliente (profiles)
        try {
            val profiles = client.postgrest["profiles"]
                .select(Columns.list("id", "full_name", "email")) {
                    filter {
                        eq("id", uuid)
                    }
                    limit(1)
                }.decodeList<ProfileRecord>()

            if (profiles.isNotEmpty()) {
                val clientProf = profiles.first()
                val clientName = clientProf.full_name ?: clientProf.email ?: "Cliente"

                // Incrementar visitas vía RPC
                val rpcRes = client.postgrest.rpc(
                    function = "increment_visits",
                    parameters = buildJsonObject {
                        put("p_profile_id", clientProf.id)
                        put("p_store_id", activeStoreId)
                        put("p_amount", 1)
                    }
                ).decodeAs<IncrementVisitsResponse>()

                // Registrar transacción en loyalty_transactions
                try {
                    client.postgrest["loyalty_transactions"].insert(
                        InsertTxPayload(
                            store_id = activeStoreId,
                            profile_id = clientProf.id,
                            visits_change = 1,
                            description = "Visita Registrada",
                            staff_id = currentStaffId
                        )
                    )
                } catch (e: Exception) {
                    Log.e("SupabaseManager", "Error inserting transaction: ${e.message}")
                }

                val isCycleUnlocked = rpcRes.cycle_unlocked ?: false
                val currentStamps = rpcRes.stamps_current ?: rpcRes.visits ?: 1
                val targetStamps = rpcRes.stamp_target ?: 10
                val rewardTitle = rpcRes.reward_title ?: "1 Recompensa Especial"

                val result = if (isCycleUnlocked) {
                    ScanProcessResult(
                        type = ScanResultType.REWARD,
                        title = "🎉 ¡Tarjeta Completada!",
                        subtitle = "¡Desbloqueó: $rewardTitle!",
                        clientName = clientName,
                        detail = "Se generó su cupón de premio automáticamente.",
                        isCycleUnlocked = true
                    )
                } else {
                    ScanProcessResult(
                        type = ScanResultType.VISIT,
                        title = "⭐ ¡Visita Registrada!",
                        subtitle = "$currentStamps de $targetStamps sellos acumulados",
                        clientName = clientName,
                        detail = "+1 Sello añadido a su tarjeta de lealtad.",
                        isCycleUnlocked = false
                    )
                }

                _lastScanResult.value = result
                return result
            }
        } catch (e: Exception) {
            Log.e("SupabaseManager", "Error al verificar cliente: ${e.message}")
        }

        // 3. No reconocido
        val notFound = ScanProcessResult(
            type = ScanResultType.ERROR,
            title = "Código No Reconocido",
            subtitle = "El código no pertenece a ningún cliente o cupón activo en el sistema."
        )
        return notFound
    }

    private fun extractUUID(text: String): String? {
        val trimmed = text.trim()
        val pattern = Pattern.compile("[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}")
        val matcher = pattern.matcher(trimmed)
        return if (matcher.find()) {
            matcher.group().lowercase()
        } else {
            null
        }
    }

    companion object {
        @Volatile
        private var instance: SupabaseManager? = null

        fun initialize(context: Context): SupabaseManager {
            return instance ?: synchronized(this) {
                instance ?: SupabaseManager(context.applicationContext).also { instance = it }
            }
        }

        fun getInstance(): SupabaseManager {
            return instance ?: throw IllegalStateException("SupabaseManager must be initialized before use.")
        }
    }
}

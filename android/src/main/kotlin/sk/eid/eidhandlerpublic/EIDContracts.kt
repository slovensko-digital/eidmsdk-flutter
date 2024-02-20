package sk.eid.eidhandlerpublic

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.activity.result.contract.ActivityResultContract
import java.io.IOException

/** A set of EID contracts. */
@Suppress("DEPRECATION")
object EIDContracts {

    /** Contact for [EIDHandler.getCertificates]. */
    open class GetCertificates : ActivityResultContract<Intent, Result<String>>() {

        override fun createIntent(context: Context, input: Intent): Intent = input

        override fun parseResult(resultCode: Int, intent: Intent?): Result<String> {
            Log.d("GetCertificates", "result: resultCode=$resultCode, extras=${intent?.extras?.keySet()?.toList()}")

            return if (
                resultCode == Activity.RESULT_OK &&
                intent?.extras?.containsKey("CERTIFICATES") == true
            ) {
                val certificatesJson = intent.getStringExtra("CERTIFICATES")!!

                Result.success(certificatesJson)
            } else if (intent?.extras?.containsKey("EXCEPTION") == true) {
                 val error = intent.getSerializableExtra("EXCEPTION") as Throwable

                Result.failure(error)
            } else {
                Result.failure(IOException("Invalid or empty result."))
            }
        }
    }

    /** Contact for [EIDHandler.startSign]. */
    open class StartSign : ActivityResultContract<Intent, Result<String>>() {

        override fun createIntent(context: Context, input: Intent): Intent = input

        override fun parseResult(resultCode: Int, intent: Intent?): Result<String> {
            Log.d("SignData", "result: resultCode=$resultCode, extras=${intent?.extras?.keySet()?.toList()}")

            return if (
                resultCode == Activity.RESULT_OK &&
                intent?.extras?.containsKey("SIGNED_DATA") == true
            ) {
                val signedData = intent.getStringExtra("SIGNED_DATA")!!

                Result.success(signedData)
            } else if (intent?.extras?.containsKey("EXCEPTION") == true) {
                val error = intent.getSerializableExtra("EXCEPTION") as Throwable

                Result.failure(error)
            } else {
                Result.failure(IOException("Invalid or empty result."))
            }
        }
    }
}

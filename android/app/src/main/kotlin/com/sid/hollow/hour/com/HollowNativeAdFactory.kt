package com.sid.hollow.hour.com

import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

/**
 * Inflates hollow_native small/medium layouts and binds AdMob assets.
 */
class HollowNativeAdFactory(
    private val layoutInflater: LayoutInflater,
) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>?,
    ): NativeAdView {
        val format = (customOptions?.get("format") as? String)?.lowercase() ?: "small"
        val isDark = when (val raw = customOptions?.get("isDark")) {
            is Boolean -> raw
            is String -> raw.equals("true", ignoreCase = true)
            else -> true
        }
        val isMedium = format == "medium"

        val layoutId =
            if (isMedium) R.layout.native_ad_medium else R.layout.native_ad_small
        val adView = layoutInflater.inflate(layoutId, null) as NativeAdView

        val surface = if (isDark) {
            Color.parseColor("#121010")
        } else {
            Color.WHITE
        }
        adView.setBackgroundColor(surface)

        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val ctaView = adView.findViewById<TextView>(R.id.ad_call_to_action)
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        val starsView = adView.findViewById<RatingBar>(R.id.ad_stars)
        val attributionView = adView.findViewById<TextView>(R.id.ad_attribution)
        val mediaView = if (isMedium) {
            adView.findViewById<MediaView>(R.id.ad_media)
        } else {
            null
        }

        adView.headlineView = headlineView
        adView.bodyView = bodyView
        adView.callToActionView = ctaView
        adView.iconView = iconView
        adView.starRatingView = starsView
        if (mediaView != null) {
            adView.mediaView = mediaView
        }

        headlineView.text = nativeAd.headline

        val body = nativeAd.body
        if (body.isNullOrBlank()) {
            bodyView.visibility = View.GONE
        } else {
            bodyView.visibility = View.VISIBLE
            bodyView.text = body
        }

        val cta = nativeAd.callToAction
        if (cta.isNullOrBlank()) {
            ctaView.visibility = View.GONE
        } else {
            ctaView.visibility = View.VISIBLE
            ctaView.text = cta
        }

        val icon = nativeAd.icon
        if (icon == null) {
            iconView.visibility = View.GONE
        } else {
            iconView.visibility = View.VISIBLE
            iconView.setImageDrawable(icon.drawable)
        }

        val rating = nativeAd.starRating
        if (rating == null) {
            starsView.visibility = View.GONE
        } else {
            starsView.visibility = View.VISIBLE
            starsView.rating = rating.toFloat()
            starsView.progressTintList =
                ColorStateList.valueOf(Color.parseColor("#C41E1E"))
            starsView.secondaryProgressTintList =
                ColorStateList.valueOf(Color.parseColor("#8B1A1A"))
        }

        if (mediaView != null) {
            val hasMedia = nativeAd.mediaContent != null
            mediaView.visibility = if (hasMedia) View.VISIBLE else View.GONE
            if (hasMedia) {
                mediaView.mediaContent = nativeAd.mediaContent
            }
        }

        // Must be last — SDK may reset TextView colors.
        adView.setNativeAd(nativeAd)

        val headlineColor =
            if (isDark) Color.parseColor("#EBEBEB") else Color.parseColor("#1A1A1A")
        val bodyColor =
            if (isDark) Color.parseColor("#8A8A8A") else Color.parseColor("#666666")
        val badgeColor = Color.parseColor("#C41E1E")

        headlineView.setTextColor(headlineColor)
        bodyView.setTextColor(bodyColor)
        attributionView.setTextColor(badgeColor)

        val badgeBg = attributionView.background
        if (badgeBg is GradientDrawable) {
            badgeBg.setStroke(attributionView.resources.displayMetrics.density.toInt().coerceAtLeast(1), badgeColor)
        }

        return adView
    }
}

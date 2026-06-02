package com.budgetfamiliar.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Widget de pantalla de inicio — muestra el balance mensual.
 *
 * Los datos los escribe el lado Flutter a través de home_widget con las claves:
 *   - "widget_balance"  : String formateado ("$ 1,234.56")
 *   - "widget_income"   : String formateado
 *   - "widget_expense"  : String formateado
 *   - "widget_label"    : String (ej. "Balance de junio 2026")
 *   - "widget_balance_color" : Int (color ARGB, opcional)
 */
class BalanceWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val prefs: SharedPreferences = HomeWidgetPlugin.getData(context)

            val balance = prefs.getString("widget_balance", "$ 0.00") ?: "$ 0.00"
            val income  = prefs.getString("widget_income",  "$ 0.00") ?: "$ 0.00"
            val expense = prefs.getString("widget_expense", "$ 0.00") ?: "$ 0.00"
            val label   = prefs.getString("widget_label",   "Balance mensual") ?: "Balance mensual"

            val views = RemoteViews(context.packageName, R.layout.balance_widget)
            views.setTextViewText(R.id.widget_balance, balance)
            views.setTextViewText(R.id.widget_income,  income)
            views.setTextViewText(R.id.widget_expense, expense)
            views.setTextViewText(R.id.widget_label,   label)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

#if defined _zpsp_cash
	#endinput
#endif
#define _zpsp_cash

// For noobs
#define CH_TEAM_ZOMBIE ZP_TEAM_ZOMBIE
#define CH_TEAM_HUMAN ZP_TEAM_HUMAN
#define CH_PLUGIN_HANDLED ZP_PLUGIN_HANDLED
#define CH_PLUGIN_SUPERCEDE ZP_PLUGIN_SUPERCEDE

/**
 * Returns a player cash
 *
 * @param id		Player index.
 * @return		True if it is, false otherwise.
 */

native zp_get_user_cash(id);

/**
 * Set a player cash to amount
 *
 * @param id		Player index.
 * @param amount        cash amount.
 */
native zp_set_user_cash(id, amount);

/**
 * Resent a player cash to 0
 *
 * @param id		Player index.
 */

native zp_reset_user_cash(id);

 /**
 * Reset Player cash up to billions.
 *
 * @param id		Player index.
 */

native zp_set_user_ultimate_cash(id);

/**
 * Add menu text in a cash extra itens
 * 
 * @param text		Text
 * @return			True if sucess / false otherwise
 */
native zp_cash_item_textadd(const text[]);

/**
 * Registers a custom item which will be added to the cash extra items menu of ZP.
 *
 * @note The returned extra item ID can be later used to catch item
 * purchase events for the CH_extra_item_selected() forward.
 *
 *
 * @param name		    Caption to display on the menu.
 * @param description	Extra item description
 * @param cost		    Ammo packs to be deducted on purchase.
 * @param teams		    Bitsum of teams it should be available for.
 * @return              An internal extra item ID, or -1 on failure.
 * @error			    If Extra Item name alterady exists
 */
native zp_register_cash_item(const name[], const description[], cost, team);

/**
 * Called when a player buys a cash item from the cash menu.
 *
 * Note: You can now return ZP_PLUGIN_HANDLED in your plugin to block
 * the purchase and the player will be automatically refunded.
 *
 * @param id		Player index of purchaser.
 * @param itemid	Internal extra item ID.
 */
forward zp_cash_item_selected(id, itemid);

/**
 * Called while player are choosing cash item
 *
 * @note Use the ZP_PLUGIN_HANDLED for block option (Like ZP 5.0)
 * @note Use the ZP_PLUGIN_SUPERCEDE for block showing item in menu
 * @note Use 'zp_cash_item_textadd' for add a small text description
 *
 * @param id		Player index
 * @param itemid	Extra item index
 */
forward zp_cash_item_selected_pre(id, itemid);
/**
 * Copyright (c) UNA, Inc - https://una.io
 * MIT License - https://opensource.org/licenses/MIT
 *
 * @defgroup    Ads Ads
 * @ingroup     UnaModules
 *
 * @{
 */

function BxAdsMain(oOptions) {
    this._sActionsUri = oOptions.sActionUri;
    this._sActionsUrl = oOptions.sActionUrl;
    this._sObjName = oOptions.sObjName == undefined ? 'oBxAdsMain' : oOptions.sObjName;
    this._sAnimationEffect = oOptions.sAnimationEffect == undefined ? 'slide' : oOptions.sAnimationEffect;
    this._iAnimationSpeed = oOptions.iAnimationSpeed == undefined ? 'slow' : oOptions.iAnimationSpeed;
    this._aHtmlIds = oOptions.aHtmlIds == undefined ? {} : oOptions.aHtmlIds;
    this._oRequestParams = oOptions.oRequestParams == undefined ? {} : oOptions.oRequestParams;
}

BxAdsMain.prototype.registerTracker = function(iId) {
    var $this = this;
    var sIdAd = $this._aHtmlIds['unit'] + iId;

    var fRegister = function(bCheckOverlap) {
        if(typeof window.glBxAdsTracked === 'undefined')
            window.glBxAdsTracked = [];

        $(window).on('load scroll', function() {
            var sIdAd = $this._aHtmlIds['unit'] + iId;

            if(glBxAdsTracked[sIdAd])
                return;

            var oElement = document.getElementById(sIdAd);
            if(oElement && $this.isVisible(oElement, bCheckOverlap)) {
                $this.registerImpression(oElement, iId);

                glBxAdsTracked[sIdAd] = true;
            }
        });
    };

    var oItem = $('#' + sIdAd);
    if(oItem.has('img.bx-base-text-unit-cover').length != 0)
        oItem.find('img.bx-base-text-unit-cover').load(function() {
            fRegister(false);
        });
    else
        fRegister(true);
};

BxAdsMain.prototype.registerTrakerForTimeline = function(iId, sHtmlId) {
    var $this = this;

    if(typeof window.glBxAdsTracked === 'undefined')
        window.glBxAdsTracked = [];

    $(window).on('load scroll', function() {
        if(glBxAdsTracked[sHtmlId])
            return;

        var oEvent = $('#' + sHtmlId).parents('.bx-tl-item:first');
        if(!oEvent || oEvent.length == 0)
            return;

        oEvent = oEvent.get(0);
        if(oEvent && $this.isVisible(oEvent, true)) {
            $this.registerImpression(oEvent, iId);

            glBxAdsTracked[sHtmlId] = true;
        }
    });
};

BxAdsMain.prototype.registerImpression = function(oElement, iId) {
    jQuery.get (
        this._sActionsUrl + 'register_impression/' + iId,
        this._getDefaultData(),
        function(oData) {
            processJsonData(oData);
        },
        'json'
    );
};

BxAdsMain.prototype.registerClick = function(oElement, iId) {
    jQuery.get (
        this._sActionsUrl + 'register_click/' + iId,
        this._getDefaultData(),
        function(oData) {
            processJsonData(oData);
        },
        'json'
    );

    return false;
};

BxAdsMain.prototype.isVisible = function(oElement, bCheckOverlap) {
    var rect = oElement.getBoundingClientRect();
    var vWidth = window.innerWidth || document.documentElement.clientWidth;
    var vHeight = window.innerHeight || document.documentElement.clientHeight;
    var fEfp = function (x, y) { 
        return document.elementFromPoint(x, y) 
    };

    if(rect.right < 0 || rect.bottom < 0 || rect.left > vWidth || rect.top > vHeight)
        return false;

    if(!bCheckOverlap)
        return true

    return (oElement.contains(fEfp(rect.left,  rect.top)) || oElement.contains(fEfp(rect.right, rect.top)) || oElement.contains(fEfp(rect.right, rect.bottom)) || oElement.contains(fEfp(rect.left,  rect.bottom)));
};

BxAdsMain.prototype.loadingInBlock = function(e, bShow) {
    var oParent = $(e).length ? $(e).parents('.bx-db-container:first') : $('body'); 
    bx_loading(oParent, bShow);
};

BxAdsMain.prototype._getDefaultData = function() {
    var oDate = new Date();
    return jQuery.extend({}, this._oRequestParams, {_t:oDate.getTime()});
};

/** @} */

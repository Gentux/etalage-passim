## -*- coding: utf-8 -*-


## Etalage-Passim -- Customization of Etalage for Passim
## By: Emmanuel Raviart <eraviart@easter-eggs.com>
##
## Copyright (C) 2011, 2012, 2013 Easter-eggs
## http://gitorious.org/passim/etalage-passim
##
## This file is part of Etalage-Passim.
##
## Etalage-Passim is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## Etalage-Passim is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.


<%!
from etalagepassim import conf, urls
%>


<%def name="body_content()" filter="trim">
    % if ctx.container_base_url is None or ctx.gadget_id is None:
    <%self:topbar/>
    <%self:site_header/>
    % endif
    <div class="container"><div class="row">
        <%self:container_content/>
        <%self:footer/>
    </div></div>
</%def>


<%def name="container_content()" filter="trim">
</%def>


<%def name="css()" filter="trim">
    % if ctx.container_base_url is not None and ctx.gadget_id is not None:
    <link rel="stylesheet" href="${conf['bootstrap-gadget.css']}">
    % else:
    <link rel="stylesheet" href="${conf['bootstrap.css']}">
    % endif
    <link rel="stylesheet" href="${conf['bootstrap-responsive.css']}">
    <link rel="stylesheet" href="${conf['typeahead.css']}">
    <link rel="stylesheet" href="${conf['jquery-ui.css']}">
    <link rel="stylesheet" href="/css/site.css">
    % if ctx.container_base_url is not None and ctx.gadget_id is not None:
    <link rel="stylesheet" href="/css/gadget.css">
    % else:
    <link rel="stylesheet" href="/css/standalone.css">
    % endif
    <link rel="stylesheet" href="/css/responsive.css">
    % if getattr(ctx, 'custom_css_url', None):
    <link rel="stylesheet" href="${ctx.custom_css_url}">
    % endif
</%def>


<%def name="export_link()" filter="trim">
                            <a href="${urls.get_url(ctx, 'export', 'annuaire', 'csv')}">
                                ${_('Export')}
                            </a>
</%def>


<%def name="feeds()" filter="trim">
    <link rel="alternate" type="application/atom+xml" href="/feed">
</%def>

<%def name="footer()" filter="trim">
        <footer class="footer">
            <%self:footer_content/>
        </footer>
</%def>


<%def name="footer_content()" filter="trim">
            <%self:footer_actions/>
            <%self:footer_service/>
</%def>


<%def name="footer_actions()" filter="trim">
</%def>


<%def name="footer_data_p_content()" filter="trim">
                ${_('Data')} :
                <a href="http://www.data.gouv.fr/Licence-Ouverte-Open-Licence" rel="external">${_('Open license')}</a>
</%def>


<%def name="footer_service()" filter="trim">
            <a href="/about">${_('Legal notice')}</a>
</%def>


<%def name="links()" filter="trim">
</%def>


<%def name="metas()" filter="trim">
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="keywords" content="directory,transport,annuaire de services,France">
</%def>


<%def name="scripts()" filter="trim">
<!--[if lt IE 9]>
    <script src="//html5shim.googlecode.com/svn/trunk/html5.js"></script>
<![endif]-->
    <script src="${conf['jquery.js']}"></script>
    <script src="${conf['bootstrap.js']}"></script>
    <script src="${conf['typeahead.js']}"></script>
    % if ctx.container_base_url is not None and ctx.gadget_id is not None:
    <script src="${conf['easyxdm.js']}"></script>
<!--[if lt IE 8]>
    <script src="${conf['json2.js']}"></script>
<![endif]-->
    <script>
var comarquage = comarquage || {};
if (!comarquage.easyXDM) {
    comarquage.easyXDM = easyXDM.noConflict("comarquage");
}
    </script>
    <script src="/js/gadget.js"></script>
    <script>
var swfUrl = ${conf['easyxdm.swf'] | n, js};
if (swfUrl.search(/\/\//) === 0) {
    swfUrl = document.location.protocol + swfUrl;
}
comarquage.rpc = new comarquage.easyXDM.Rpc({
    swf: swfUrl
},
{
    remote: {
        adjustHeight: {},
        requestNavigateTo: {}
    }
});
    </script>
    % endif
</%def>


<%def name="scripts_domready()" filter="trim">
    <script>
$(function () {
    <%self:scripts_domready_content/>
});
    </script>
</%def>


<%def name="scripts_domready_content()" filter="trim">
    % if ctx.container_base_url is not None and ctx.gadget_id is not None:
    initGadget();
    % endif
    $("a[href=#]").on('click', function (e) {
        e.preventDefault();
        return false;
    });
</%def>


<%def name="share_link()" filter="trim">
                            <a href="${urls.get_url(ctx, 'gadget')}">${_('Share')}</a>
</%def>


<%def name="site_header()" filter="trim">
    <header class="jumbotron subhead" id="overview">
        <div class="container">
            <img src="/img/logo-ministere.png">
            <h2>${_('PASSIM')}</h2>
            <p class="lead">
                ${_('Directory of Traveler Information Services in France')}<br>
                <small>( ${_('Beta')} )</small>
            </p>
        </div>
    </header>
</%def>


<%def name="title_content()" filter="trim">
Passim.info
</%def>


<%def name="topbar()" filter="trim">
    <div class="navbar navbar-fixed-top">
        <div class="navbar-inner">
            <div class="container">
                <button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </button>
                <a class="brand" href="${urls.get_url(ctx)}">${_('PASSIM')}</a>
                <div class="nav-collapse collapse">
                    <ul class="nav">
                        <li><a href="/about">${_('About')}</a></li>
                        <li><a href="/contact">${_('Contact')}</a></li>
                        <li><a href="/contribute">${_('Contribute')}</a></li>
                        <li><a href="/data">${_('Reuse')}</a></li>
                        <li><a href="/help">${_('Help')}</a></li>
                        <li class="dropdown">
                            <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                                Cartographie<b class="caret"></b>
                            </a>
                            <ul class="dropdown-menu">
                                <li><a href="/donnees/sim.htm">Service d'information Multimodale</a></li>
                                <li><a href="/donnees/reg.htm">Service d'information par région</a></li>
                                <li><a href="/donnees/dep.htm">Service d'information par départements</a></li>
                                <li class="divider"></li>
                                <li><a href="/donnees/offres.htm">Offres de transport</a></li>
                            </ul>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
</%def>


<%def name="trackers()" filter="trim">
    % if conf['markers.piwik.id'] is not None:
    <!-- Piwik -->
    <script type="text/javascript">
var pkBaseURL = (("https:" == document.location.protocol) ? ${conf['markers.piwik.ssl_host'] | n, js} : ${conf['markers.piwik.host'] | n, js});
document.write(unescape("%3Cscript src='" + pkBaseURL + "piwik.js' type='text/javascript'%3E%3C/script%3E"));
    </script><script type="text/javascript">
try {
    var piwikTracker = Piwik.getTracker(pkBaseURL + "piwik.php", ${conf['markers.piwik.id']});
        % if ctx.container_base_url is not None:
    piwikTracker.setCustomVariable(2, "container_base_url", ${ctx.container_base_url | n, js}, "visit");
        % endif
    piwikTracker.trackPageView();
    piwikTracker.enableLinkTracking();
} catch( err ) {}
    </script><noscript><p><img src="${conf['markers.piwik.host']}/piwik.php?idsite=${conf['markers.piwik.id']}" style="border:0" alt="" /></p></noscript>
    <!-- End Piwik Tracking Code -->
    % endif
</%def>


<!DOCTYPE html>
<html lang="${ctx.lang[0][:2]}">
<head>
    <%self:metas/>
    <title>${self.title_content()}</title>
    <%self:links/>
    <%self:feeds/>
    <%self:css/>
    <%self:scripts/>
    <%self:scripts_domready/>
</head>
<body>
    <%self:body_content/>
    <%self:trackers/>
</body>
</html>

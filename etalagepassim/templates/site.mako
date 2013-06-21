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
    <div class="container-fluid"><div class="row-fluid">
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
                                ${_('Export data in CSV format')}
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
            <p>
                <%self:footer_data_p_content/>
            </p>
            <p>
                ${_("Software")} :
                <a href="http://gitorious.org/passim/etalage-passim" rel="external">${_("Passim")}</a>
                &mdash;
                <span>${_(u"Copyright © 2011, 2012, 2013 ")}<a href="http://www.easter-eggs.com/" rel="external"
                        title="Easter-eggs, société de services en logiciels libres">${_("Easter-eggs")}</a></span>
                &mdash;
                ${_('Open license')}
                <a href="http://www.gnu.org/licenses/agpl.html" rel="external">${_(
                    'GNU Affero General Public License')}</a>
            </p>
</%def>


<%def name="footer_actions()" filter="trim">
</%def>


<%def name="footer_data_p_content()" filter="trim">
                ${_('Data')} :
                <a href="http://www.data.gouv.fr/Licence-Ouverte-Open-Licence" rel="external">${_('Open license')}</a>
</%def>


<%def name="footer_service()" filter="trim">
            <p>
                ${_('Service proposed by ')}
                <a href="http://www.cete-mediterranee.fr/tt13/www/rubrique.php3?id_rubrique=27" rel="external">${_(u'CETE Méditerranée')}</a>
                ${_('for')}
                <a href="http://www.developpement-durable.gouv.fr/Presentation-de-l-AFIMB.html" rel="external">${_(u'AFIMB')}</a>
                ${_('and the')} <a href="http://www.predim.org/">${_('Mission Transports Intelligents de la DGITM')}</a>,
                ${_('made by')} <a href="http://www.easter-eggs.com/" rel="external" \
title="${_('Easter-eggs, Free software services company')}">${_('Easter-eggs')}</a>.
            </p>
</%def>


<%def name="links()" filter="trim">
</%def>


<%def name="metas()" filter="trim">
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
</%def>


<%def name="site_header()" filter="trim">
    <header class="jumbotron subhead">
        <div class="container well">
            <img src="/img/logo-ministere.png">
            <h1>${_('PASSIM')}</h1>
            <p class="lead">${_('Transport information services and site directory.')}</p>
        </div>
    </header>
</%def>


<%def name="title_content()" filter="trim">
Étalage - Comarquage.fr
</%def>


<%def name="topbar()" filter="trim">
    <div class="navbar navbar-fixed-top">
        <div class="navbar-inner">
            <div class="container-fluid">
                <button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </button>
                <a class="brand" href="${urls.get_url(ctx)}">${_('PASSIM')}</a>
                <div class="nav-collapse collapse">
                    <ul class="nav">
    % if conf['data_email'] is not None:
                        <li>
                            <a \
href="mailto:${u','.join(conf['data_email'])}?subject=${_('New Passim POI').replace(u' ', u'%20')}&body=${_(u'''
Please add following information service :

Name : ...
Geographical coverage : ....
Transport modes : ....
Web site : ...
Mobile Application : ...
Call center : ...
Information desk : ...
OpenData : ...
Notes : ...
''').strip().replace(u' ', u'%20').replace(u'\n', u'%0a')}">${_('Add a POI')}</a>
                        </li>
    % endif

                        <li>
                            <%self:export_link/>
                        </li>
                        <li><a href="/about">${_('About')}</a></li>
                        <li><a href="/contact">${_('Contact')}</a></li>
                        <li><a href="/contribute">${_('Contribute')}</a></li>
                        <li><a href="/data">${_('Data')}</a></li>
                        <li><a href="/help">${_('Help')}</a></li>
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

from django.contrib.sites.models import get_current_site
from cilantro.models import SiteConfiguration


def static(request):
    from django.conf import settings
    static_url = getattr(settings, 'CILANTRO_STATIC_URL', None)

    if static_url is None:
        static_url = settings.STATIC_URL + 'cilantro'

    javascript_url = '{}/scripts/javascript/{}'.format(static_url,
        'src' if settings.DEBUG else 'min')

    css_url = '{}/stylesheets/css'.format(static_url)
    images_url = '{}/images'.format(static_url)

    return {
        'CILANTRO_STATIC_URL': static_url,
        'CILANTRO_JAVASCRIPT_URL': javascript_url,
        'CILANTRO_CSS_URL': css_url,
        'CILANTRO_IMAGES_URL': images_url,
    }


def configuration(request):
    site = get_current_site(request)
    try:
        config = site.configuration
    except SiteConfiguration.DoesNotExist:
        config = None
    return {
        'CILANTRO_CONFIG': config,
    }

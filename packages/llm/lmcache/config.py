from jetson_containers import update_dependencies


def lmcache(version, repo=None, branch=None, requires=None, default=False, depends=None):
    pkg = package.copy()

    if requires:
        pkg['requires'] = requires

    if depends:
        pkg['depends'] = update_dependencies(pkg['depends'], depends)

    suffix = version if version else branch
    branch = branch if branch else f'v{version}'

    pkg['name'] = f'lmcache:{suffix.replace("+", ".")}'
    pkg['build_args'] = {
        'LMCACHE_REPO': repo if repo else 'https://github.com/wtdcode/LMCache.git',
        'LMCACHE_VERSION': version,
        'LMCACHE_BRANCH': branch,
    }

    builder = pkg.copy()
    builder['name'] = f'lmcache:{suffix.replace("+", ".")}-builder'
    builder['build_args'] = {**pkg['build_args'], **{'FORCE_BUILD': 'on'}}

    if default:
        pkg['alias'] = 'lmcache'
        builder['alias'] = 'lmcache:builder'

    return pkg, builder


package = [
    lmcache('0.13.1',
            repo='https://github.com/wtdcode/LMCache.git',
            branch='vllm-backport-0.13',
            default=True),
]

from jetson_containers import IS_SBSA, update_dependencies, cuda_short_version


def vllm(version, repo=None, branch=None, requires=None, default=False, depends=None):
    pkg = package.copy()

    if requires:
        pkg['requires'] = requires

    if depends:
        pkg['depends'] = update_dependencies(pkg['depends'], depends)

    suffix = version if version else branch
    branch = branch if branch else f'v{version}'

    pkg['name'] = f'vllm:{suffix.replace("+", ".")}'
    pkg['build_args'] = {
        'VLLM_REPO': repo if repo else 'https://github.com/vllm-project/vllm.git',
        'VLLM_VERSION': version,
        'VLLM_BRANCH': branch,
        'IS_SBSA': IS_SBSA,
        'CUDA_SUFFIX': cuda_short_version()
    }

    builder = pkg.copy()
    builder['name'] = f'vllm:{suffix.replace("+", ".")}-builder'
    builder['build_args'] = {**pkg['build_args'], **{'FORCE_BUILD': 'on'}}

    if default:
        pkg['alias'] = 'vllm'
        builder['alias'] = 'vllm:builder'

    return pkg, builder

package = [
    vllm('0.21.0', depends=['flashinfer'], default=False),
    vllm('0.23.0', depends=['flashinfer'], default=False),
    vllm('0.23.1rc0', depends=['flashinfer'], default=False),
    vllm('0.25.0', depends=['flashinfer'], default=False),
    vllm('0.26.0', depends=['flashinfer'], default=False),
    vllm('0.27.0.dev0', depends=['flashinfer'], default=False),
    vllm('0.27.1', depends=['flashinfer'], default=False),
    vllm('0.28.0', depends=['flashinfer'], default=True),
    vllm('0.10.0+wtdcode', repo='https://github.com/wtdcode/vllm-backport.git', branch='v0.10.0',  depends=['flashinfer'], default=False),

]

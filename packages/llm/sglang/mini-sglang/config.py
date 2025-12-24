from jetson_containers import CUDA_VERSION, IS_SBSA, update_dependencies

def minisgl(version, branch=None, depends=None, default=False):
    pkg = package.copy()

    if not branch:
        branch = f'v{version}'

    if depends:
        pkg['depends'] = update_dependencies(pkg['depends'], depends)

    pkg['name'] = f'mini-sglang:{version}'

    pkg['build_args'] = {
        'MINISGL_VERSION': version,
        'MINISGL_BRANCH': branch,
        'IS_SBSA': IS_SBSA,
    }

    builder = pkg.copy()

    builder['name'] = f'mini-sglang:{version}-builder'
    builder['build_args'] = {**pkg['build_args'], **{'FORCE_BUILD': 'on'}}

    if default:
        pkg['alias'] = 'mini-sglang'
        builder['alias'] = 'mini-sglang:builder'

    return pkg, builder

package = [
    minisgl('latest', branch='main', depends=['flashinfer', 'sgl-kernel'], default=True)
]


from jetson_containers import CUDA_ARCHITECTURES

def dwarf_star(version, branch=None, default=False):
    """
    Define container that builds ds4 (DwarfStar) inference engine from source.
    """
    if not branch:
        branch = f'v{version}'

    pkg = package.copy()

    pkg['name'] = f'dwarf_star:{version}'

    pkg['build_args'] = {
        'DWARF_STAR_VERSION': version,
        'DWARF_STAR_BRANCH': branch,
        'CUDA_ARCHITECTURES': ';'.join([str(x) for x in CUDA_ARCHITECTURES]),
    }

    builder = pkg.copy()
    builder['name'] = builder['name'] + '-builder'
    builder['build_args'] = {**builder['build_args'], 'FORCE_BUILD': 'on'}

    if default:
        pkg['alias'] = 'dwarf_star'
        builder['alias'] = 'dwarf_star:builder'

    return pkg, builder

package = [
    dwarf_star('latest',branch="main", default=True),
]

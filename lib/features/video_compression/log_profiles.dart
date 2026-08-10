class LogProfile {
  final String id;
  final String displayName;
  final String filterChain;

  const LogProfile({
    required this.id,
    required this.displayName,
    required this.filterChain,
  });
}

const String _hableToneMap =
    'zscale=transfer=linear:npl=100,format=gbrpf32le,zscale=p=bt709,'
    'tonemap=hable:desat=0,zscale=transfer=bt709:matrix=bt709:range=tv,'
    'format=yuv420p,scale={w}:{h}';

const String _hableToneMapNpl200 =
    'zscale=transfer=linear:npl=200,format=gbrpf32le,zscale=p=bt709,'
    'tonemap=hable:desat=0,zscale=transfer=bt709:matrix=bt709:range=tv,'
    'format=yuv420p,scale={w}:{h}';

const String _reinhardToneMap =
    'zscale=transfer=linear,format=gbrpf32le,zscale=p=bt709,'
    'tonemap=reinhard:desat=0,zscale=transfer=bt709:matrix=bt709:range=tv,'
    'format=yuv420p,scale={w}:{h}';

const List<LogProfile> logProfiles = [
  LogProfile(
    id: 'standard',
    displayName: 'Standard SDR',
    filterChain: 'scale={w}:{h},format=yuv420p',
  ),
  LogProfile(
    id: 'slog2',
    displayName: 'S-Log2 (Sony)',
    filterChain: _hableToneMap,
  ),
  LogProfile(
    id: 'slog3',
    displayName: 'S-Log3 (Sony)',
    filterChain: _hableToneMap,
  ),
  LogProfile(
    id: 'dlog',
    displayName: 'D-Log (DJI)',
    filterChain: _reinhardToneMap,
  ),
  LogProfile(
    id: 'dlogm',
    displayName: 'D-Log M (DJI)',
    filterChain: _reinhardToneMap,
  ),
  LogProfile(
    id: 'clog',
    displayName: 'C-Log (Canon)',
    filterChain: _hableToneMap,
  ),
  LogProfile(
    id: 'clog2',
    displayName: 'C-Log2 (Canon)',
    filterChain: _hableToneMapNpl200,
  ),
  LogProfile(
    id: 'clog3',
    displayName: 'C-Log3 (Canon)',
    filterChain: _hableToneMap,
  ),
  LogProfile(
    id: 'vlog',
    displayName: 'V-Log (Panasonic)',
    filterChain: _hableToneMap,
  ),
  LogProfile(
    id: 'vlogl',
    displayName: 'V-Log L (Panasonic)',
    filterChain: _hableToneMap,
  ),
  LogProfile(
    id: 'hlg',
    displayName: 'HLG (Broadcast/iPhone)',
    filterChain:
        'zscale=transfer=linear:npl=1000,format=gbrpf32le,zscale=p=bt709,'
        'tonemap=hable:desat=0,zscale=transfer=bt709:matrix=bt709:range=tv,'
        'format=yuv420p,scale={w}:{h}',
  ),
];

LogProfile logProfileById(String id) {
  return logProfiles.firstWhere(
    (profile) => profile.id == id,
    orElse: () => logProfiles.first,
  );
}

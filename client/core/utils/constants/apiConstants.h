#ifndef APICONSTANTS_H
#define APICONSTANTS_H

namespace apiDefs
{

constexpr int requestTimeoutMsecs = 8 * 1000; // 8 secs (snappier UI; gateway ~0.2s over HTTP/1.1)

} // namespace apiDefs

#endif // APICONSTANTS_H

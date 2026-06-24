pragma Singleton

import QtQuick

QtObject {
    property QtObject color: QtObject {
        readonly property color transparent: 'transparent'
        readonly property color paleGray: '#F5F4EF'
        readonly property color lightGray: '#C1C2C5'
        readonly property color mutedGray: '#878B91'
        readonly property color charcoalGray: '#494B50'
        readonly property color slateGray: '#2C2D30'
        readonly property color onyxBlack: '#1C1D21'
        readonly property color midnightBlack: '#0E0E11'
        readonly property color goldenApricot: goldenApricotString
        readonly property color goldenApricotStrong: '#C8F050'
        readonly property color goldenApricotPressed: '#9FC72E'
        readonly property color benefitsPanelBackground: '#1C1C1E'
        readonly property color softViolet: '#A87BE2'
        readonly property color burntOrange: '#9FC72E'
        readonly property color mutedBrown: '#6E7A50'
        readonly property color richBrown: '#9FC72E'
        readonly property color deepBrown: '#3E4A22'
        readonly property color vibrantRed: '#EB5757'
        readonly property color darkCharcoal: '#1A1C18'
        readonly property color pearlGray: '#EAEAEC'

        readonly property color sheerWhite: Qt.rgba(1, 1, 1, 0.12)
        readonly property color translucentWhite: Qt.rgba(1, 1, 1, 0.08)
        readonly property color barelyTranslucentWhite: Qt.rgba(1, 1, 1, 0.05)
        readonly property color translucentMidnightBlack: Qt.rgba(14/255, 14/255, 17/255, 0.8)
        readonly property color softGoldenApricot: Qt.rgba(184/255, 230/255, 65/255, 0.3)
        readonly property color mistyGray: Qt.rgba(245/255, 244/255, 239/255, 0.8)
        readonly property color cloudyGray: Qt.rgba(245/255, 244/255, 239/255, 0.65)
        readonly property color translucentRichBrown: Qt.rgba(184/255, 230/255, 65/255, 0.12)
        readonly property color translucentSlateGray: Qt.rgba(85/255, 86/255, 92/255, 0.13)
        readonly property color translucentOnyxBlack: Qt.rgba(28/255, 29/255, 33/255, 0.13)

        readonly property string goldenApricotString: '#B8E641'
    }
}
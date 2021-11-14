// SPDX-License-Identifier: LGPL-3.0-only
// This file is LGPL3 Licensed
pragma solidity ^0.6.1;

/**
 * @title Elliptic curve operations on twist points for alt_bn128
 * @author Mustafa Al-Bassam (mus@musalbas.com)
 * @dev Homepage: https://github.com/musalbas/solidity-BN256G2
 */

library BN256G2 {
    uint256 internal constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 internal constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 internal constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint internal constant PTXX = 0;
    uint internal constant PTXY = 1;
    uint internal constant PTYX = 2;
    uint internal constant PTYY = 3;
    uint internal constant PTZX = 4;
    uint internal constant PTZY = 5;

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ECTwistAdd(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            if (!(
                pt2xx == 0 && pt2xy == 0 &&
                pt2yx == 0 && pt2yy == 0
            )) {
                assert(_isOnCurve(
                    pt2xx, pt2xy,
                    pt2yx, pt2yy
                ));
            }
            return (
                pt2xx, pt2xy,
                pt2yx, pt2yy
            );
        } else if (
            pt2xx == 0 && pt2xy == 0 &&
            pt2yx == 0 && pt2yy == 0
        ) {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
            return (
                pt1xx, pt1xy,
                pt1yx, pt1yy
            );
        }

        assert(_isOnCurve(
            pt1xx, pt1xy,
            pt1yx, pt1yy
        ));
        assert(_isOnCurve(
            pt2xx, pt2xy,
            pt2yx, pt2yy
        ));

        uint256[6] memory pt3 = _ECTwistAddJacobian(
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            1,     0,
            pt2xx, pt2xy,
            pt2yx, pt2yy,
            1,     0
        );

        return _fromJacobian(
            pt3[PTXX], pt3[PTXY],
            pt3[PTYX], pt3[PTYY],
            pt3[PTZX], pt3[PTZY]
        );
    }

    /**
     * @notice Multiply a twist point by a scalar
     * @param s     Scalar to multiply by
     * @param pt1xx Coefficient 1 of x
     * @param pt1xy Coefficient 2 of x
     * @param pt1yx Coefficient 1 of y
     * @param pt1yy Coefficient 2 of y
     * @return (pt2xx, pt2xy, pt2yx, pt2yy)
     */
    function ECTwistMul(
        uint256 s,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        uint256 pt1zx = 1;
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            pt1xx = 1;
            pt1yx = 1;
            pt1zx = 0;
        } else {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
        }

        uint256[6] memory pt2 = _ECTwistMulJacobian(
            s,
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            pt1zx, 0
        );

        return _fromJacobian(
            pt2[PTXX], pt2[PTXY],
            pt2[PTYX], pt2[PTYY],
            pt2[PTZX], pt2[PTZY]
        );
    }

    /**
     * @notice Get the field modulus
     * @return The field modulus
     */
    function GetFieldModulus() public pure returns (uint256) {
        return FIELD_MODULUS;
    }

    function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    function _FQ2Mul(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS),
            addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS)
        );
    }

    function _FQ2Muc(
        uint256 xx, uint256 xy,
        uint256 c
    ) internal pure returns (uint256, uint256) {
        return (
            mulmod(xx, c, FIELD_MODULUS),
            mulmod(xy, c, FIELD_MODULUS)
        );
    }

    function _FQ2Add(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            addmod(xx, yx, FIELD_MODULUS),
            addmod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Sub(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256 rx, uint256 ry) {
        return (
            submod(xx, yx, FIELD_MODULUS),
            submod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Div(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal view returns (uint256, uint256) {
        (yx, yy) = _FQ2Inv(yx, yy);
        return _FQ2Mul(xx, xy, yx, yy);
    }

    function _FQ2Inv(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        uint256 inv = _modInv(addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS), FIELD_MODULUS);
        return (
            mulmod(x, inv, FIELD_MODULUS),
            FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS)
        );
    }

    function _isOnCurve(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = _FQ2Mul(yx, yy, yx, yy);
        (xxxx, xxxy) = _FQ2Mul(xx, xy, xx, xy);
        (xxxx, xxxy) = _FQ2Mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    function _modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem,0x20), 0x20)
            mstore(add(freemem,0x40), 0x20)
            mstore(add(freemem,0x60), a)
            mstore(add(freemem,0x80), sub(n, 2))
            mstore(add(freemem,0xA0), n)
            success := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
        require(success);
    }

    function _fromJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal view returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) {
        uint256 invzx;
        uint256 invzy;
        (invzx, invzy) = _FQ2Inv(pt1zx, pt1zy);
        (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, invzx, invzy);
        (pt2yx, pt2yy) = _FQ2Mul(pt1yx, pt1yy, invzx, invzy);
    }

    function _ECTwistAddJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy) internal pure returns (uint256[6] memory pt3) {
            if (pt1zx == 0 && pt1zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt2xx, pt2xy,
                    pt2yx, pt2yy,
                    pt2zx, pt2zy
                );
                return pt3;
            } else if (pt2zx == 0 && pt2zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy
                );
                return pt3;
            }

            (pt2yx,     pt2yy)     = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1 = y2 * z1
            (pt3[PTYX], pt3[PTYY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2 = y1 * z2
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1 = x2 * z1
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2 = x1 * z2

            if (pt2xx == pt3[PTZX] && pt2xy == pt3[PTZY]) {
                if (pt2yx == pt3[PTYX] && pt2yy == pt3[PTYY]) {
                    (
                        pt3[PTXX], pt3[PTXY],
                        pt3[PTYX], pt3[PTYY],
                        pt3[PTZX], pt3[PTZY]
                    ) = _ECTwistDoubleJacobian(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
                    return pt3;
                }
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    1, 0,
                    1, 0,
                    0, 0
                );
                return pt3;
            }

            (pt2zx,     pt2zy)     = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // W = z1 * z2
            (pt1xx,     pt1xy)     = _FQ2Sub(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]); // U = U1 - U2
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2xx, pt2xy, pt3[PTZX], pt3[PTZY]); // V = V1 - V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1yx, pt1yy, pt1yx,     pt1yy);     // V_squared = V * V
            (pt2yx,     pt2yy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1zx, pt1zy, pt1yx,     pt1yy);     // V_cubed = V * V_squared
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // newz = V_cubed * W
            (pt2xx,     pt2xy)     = _FQ2Mul(pt1xx, pt1xy, pt1xx,     pt1xy);     // U * U
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt2zx,     pt2zy);     // U * U * W
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt1zx,     pt1zy);     // U * U * W - V_cubed
            (pt2zx,     pt2zy)     = _FQ2Muc(pt2yx, pt2yy, 2);                    // 2 * V_squared_times_V2
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt2zx,     pt2zy);     // A = U * U * W - V_cubed - 2 * V_squared_times_V2
            (pt3[PTXX], pt3[PTXY]) = _FQ2Mul(pt1yx, pt1yy, pt2xx,     pt2xy);     // newx = V * A
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2yx, pt2yy, pt2xx,     pt2xy);     // V_squared_times_V2 - A
            (pt1yx,     pt1yy)     = _FQ2Mul(pt1xx, pt1xy, pt1yx,     pt1yy);     // U * (V_squared_times_V2 - A)
            (pt1xx,     pt1xy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTYX], pt3[PTYY]); // V_cubed * U2
            (pt3[PTYX], pt3[PTYY]) = _FQ2Sub(pt1yx, pt1yy, pt1xx,     pt1xy);     // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    function _ECTwistDoubleJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy
    ) {
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 3);            // 3 * x
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = _FQ2Muc(pt2yx, pt2yy, 8);            // 8 * B
        (pt1xx, pt1xy) = _FQ2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = _FQ2Muc(pt2yx, pt2yy, 4);            // 4 * B
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = _FQ2Muc(pt1yx, pt1yy, 8);            // 8 * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 2);            // 2 * H
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = _FQ2Muc(pt2zx, pt2zy, 8);            // newz = 8 * S * S_squared
    }

    function _ECTwistMulJacobian(
        uint256 d,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (uint256[6] memory pt2) {
        while (d != 0) {
            if ((d & 1) != 0) {
                pt2 = _ECTwistAddJacobian(
                    pt2[PTXX], pt2[PTXY],
                    pt2[PTYX], pt2[PTYY],
                    pt2[PTZX], pt2[PTZY],
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy);
            }
            (
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            ) = _ECTwistDoubleJacobian(
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            );

            d = d / 2;
        }
    }
}



// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.6.1;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return r the sum of two points of G2
    function addition(G2Point memory p1, G2Point memory p2) internal view returns (G2Point memory r) {
        (r.X[0], r.X[1], r.Y[0], r.Y[1]) = BN256G2.ECTwistAdd(p1.X[0],p1.X[1],p1.Y[0],p1.Y[1],p2.X[0],p2.X[1],p2.Y[0],p2.Y[1]);
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.6.1;

library GetVK200 {
    using Pairing for *;
    function getvk(uint m1, uint n1, uint32[] memory iinput) public view returns (uint x1, uint  y1) {
        Pairing.G1Point[] memory data = new Pairing.G1Point[](200);
        data[0] = Pairing.G1Point(uint256(0x0d69e24fe69347ea0a234a925fa3efaf8dcd7b261737273908785614b624cb07), uint256(0x180c30387f5159ff02fadaa77aaca2df1f979e71bb09acfa49cf70faaa10a3fe));
data[1] = Pairing.G1Point(uint256(0x052ba672d76c036be179cf952df6be4388aca66f403a675d4cefb47057e85c64), uint256(0x0b6e65a7b0e97e0c7f9c9a72132291d0f92411eb20d57c2592ce685eb898ed59));
data[2] = Pairing.G1Point(uint256(0x28b632c19d516990bff8e9b9ccb6d751aeddca2f61bfecc2ff8f148b4a42632f), uint256(0x05c856016d803e1bffed891f70b861547c19914c9f742573fddb0e3092dfbacd));
data[3] = Pairing.G1Point(uint256(0x0dce94aace69b4357049b86420dd60cde7a39f157b509877219602056007a84a), uint256(0x00425ef909d66f50779a0c3d0c366619ca77fbc7a30578f70285cae0f47c7e92));
data[4] = Pairing.G1Point(uint256(0x2f9c77e66d212e4d96bac273360c801647a3a925efe17cabec7805d242d50845), uint256(0x003ce28752d47101edd585f5a2d2cab77a9b470e4a05ed8c47341c62dc17249f));
data[5] = Pairing.G1Point(uint256(0x0a1d89cecf228cbea49ec4610d07c32c7b48daea7e9555619ca1b438d5519305), uint256(0x0aeedab2ad95c226a66207ebf65714e553d674ac8edac76ee71e37d90d98526b));
data[6] = Pairing.G1Point(uint256(0x2b9463cfbaf2111c9c900a71a8911fe005cf1d71cf674c2493e2c718f2d31e86), uint256(0x01e79f6bbef3096bdf7ceffc2c3f649085a5eaefcba80c51a24d23b93ca28c63));
data[7] = Pairing.G1Point(uint256(0x20cd0b7c8dc4b6366c6b996bcf2fc024ac473ed5d7a7324fdaf0636368ad2dbc), uint256(0x26a9aaabe16f4d732faaa29b0f49a5b6431c04dfcca0f1668b46473fbec58033));
data[8] = Pairing.G1Point(uint256(0x10711299a65c21d6b123eeed78168d2b496c63fde0fa24968e0df655b96d636e), uint256(0x030f63f3a473aa4b86ba242d2e2efde5207c8a55156e861dfa784ce8900748df));
data[9] = Pairing.G1Point(uint256(0x1029db10efe3527a080f24b8dddb07fa671d3160a773b0304b2d5283b8d8d984), uint256(0x05288f7d991a39dc9dfc7abad975997e5498dc29802712a26d7cd16eabb3b403));
data[10] = Pairing.G1Point(uint256(0x005c39a02d4df5df911f5647361df47f4c7fd9bb68596d9576bd67d6ce23b729), uint256(0x2193a676b497708e1186dcbf827204ecad0dc520c1b4598a7ffd261aceb6b650));
data[11] = Pairing.G1Point(uint256(0x2d61e5e3abc1aada6573db88babed5095df1e9e9a6c25d07414c377a6357707b), uint256(0x2d22ae215bea2edecfb2594e20693aea7983f282de049ae613c23c1f0ee12c0e));
data[12] = Pairing.G1Point(uint256(0x05c56be048311a454cb9681e1f00e90dcd1efc55c62bf7ac33fca703244fca8a), uint256(0x295ab49a4ffe5a5e1bf5f89c26729f4c09f0c69d872b1f2fccc3fa990a6ebb02));
data[13] = Pairing.G1Point(uint256(0x061af5e1b3f763c4472a7d620a79b5730e734af31eafcf383acea0a5b4b9967b), uint256(0x27b5bd2154ff4ee45d879b581a9e66e81cfc3f9d319fd2f5a2ad06afd6890d0b));
data[14] = Pairing.G1Point(uint256(0x0d0dee2f9aeca4e87e004c0011d76bfc5824f0a79fe0703215335430b21aa286), uint256(0x17eb27f69837297a2c49ffdca3049978a9d8f7d6a74e8aa2f4a364fc9c87b2c9));
data[15] = Pairing.G1Point(uint256(0x2c0e295019c7b550750cc39d9fdfc96263f4e8a00d9b5ddb7ee623bd9be08b53), uint256(0x0d7327543ba2ba4cd094784f9f1bd1cfa0d513cb7e828b333e493d87cca59815));
data[16] = Pairing.G1Point(uint256(0x300290f53970f8c2c7f8b6c42b15918fa82b5544dc8746992d70f284999c1c55), uint256(0x236873879952b0d3bc4608b47c7bd4be39d2d0cbfcbef628b64574b8bc11052c));
data[17] = Pairing.G1Point(uint256(0x2aaa22efca37c266bbb567f4a2d6624b720290c47576cae8e7ca9a12bf88d800), uint256(0x2c3748c7e2a1af31934cb5e8c077db75f9a83a89f6e6b6aa7cb0ba12bd0d9642));
data[18] = Pairing.G1Point(uint256(0x069fa28442ed4ecc552009fc48ac3c29df3f7003c8d1ff178f3b9778b2c2ed39), uint256(0x1c8d07be9ee9874c35135dee45a3a189d65447c41bb5d4c5265e57d611b88e20));
data[19] = Pairing.G1Point(uint256(0x137ca8ab119235ae212d0751ed169fb81cc402a6a1e20c06c26522189c36d642), uint256(0x2682fc94b1533304a61527c877e374042755940c69289967c48ddd592e510503));
data[20] = Pairing.G1Point(uint256(0x2f85af055aae7525093a8f166c2332bbb23222528fb3da8438d834fccd040ff6), uint256(0x2fee1b9a79ba9aab93eae53603cdb649e3aadb7fdb3c35dc081987c1d08c36e2));
data[21] = Pairing.G1Point(uint256(0x137d43c594fae653be488192c7a7376828d92f1ade3fd917b6b9a2957dbd22af), uint256(0x0f1cafc57f857e3241eaf31fa633f0dd35277436cb765a27fe523433161f87b0));
data[22] = Pairing.G1Point(uint256(0x12abdcad6d18ef963e68f2b030727a4d51bd170abf7c3ca184004e326f9c0ebb), uint256(0x197357654691d58d4a2b587b98160ef4a2f8fba9e8e7a44ef2dc57d02c072312));
data[23] = Pairing.G1Point(uint256(0x1fb8cff27902ee22de09436f49ae5d6b25c7367639b54a589421ad3dcdf81226), uint256(0x1113a9d54810ab85ecfe65b4a66727bf5965d094fdac072d7dece9e31a1fe149));
data[24] = Pairing.G1Point(uint256(0x046f1d633705367115f028984f918d5e679be0656cf3b3f930ca1ffe5daeb615), uint256(0x1c2547959cda4d77fe58559c371d025c2ba617ed966438a39c1f859ab88e4ce5));
data[25] = Pairing.G1Point(uint256(0x0509304d75bfbd2cbb08df9b92b6a0e339ac85d157b044d5d404dd24b02d8a24), uint256(0x15710b13e59c988fbeab2f1b5ee2b94cec8ada289b6373d1b2ba00fce1944ba9));
data[26] = Pairing.G1Point(uint256(0x0f308ccd29eb62307d66e8ff7c9794999889a254977bfed52ca102673ba6457c), uint256(0x212c5bb0afc0f08b3cac40a725edbcd10039847a52d1695c66d4e138f3e17c2a));
data[27] = Pairing.G1Point(uint256(0x28ccdcf979b8a9d397fbed6c0de41d3dd355a2ae4af9291b3a5382c197638767), uint256(0x277893e2fa81ed58b272bd036f6a250724ed60d44b2694407d66122866f6d924));
data[28] = Pairing.G1Point(uint256(0x1897a36817e3021563fdf5d7b43fd8963a60f8c3745b3bfeba7cf00f60d2bb12), uint256(0x0858cd5a19d97c3ef51d8f64b2dc4ea930687d2d1b47733cff31212a4d1cd665));
data[29] = Pairing.G1Point(uint256(0x258a11955e6ff3a44dc9cdb892f7099f26229a8a243ed0171cc9bc1e0d260e31), uint256(0x140fdb766d2bc986adefff263b5c1c19af0d37505fae3181ae5846f5e6c12eaa));
data[30] = Pairing.G1Point(uint256(0x1877d5debd2d9d17ef75eb6cbf3c843088705256f6f3fb165d61218c201eaf6b), uint256(0x1f09d3573af8a0e3f43dff9a25905551c5494aa93eac0377030f24ab3e3abbf1));
data[31] = Pairing.G1Point(uint256(0x0012a71ac51193b1de31ba55d53ead32f6053d9db6d8d89f51122b97293dfa4c), uint256(0x16b0ab05e052f15a7b09746b0ad26ad768c6b4c445c9ae8ef56dd21292ba45ef));
data[32] = Pairing.G1Point(uint256(0x2aea31f05a7eebef9978ad99d367400a8df5d42aec7dd6c4c86ee1a7c16120b0), uint256(0x224f4c2a07fd6482c0eac2912a7944da1bb9b613a557fdd1296765c3f7972234));
data[33] = Pairing.G1Point(uint256(0x2f97611037e103a72a64734467d12bdb171f30a651708984846d69350f36d8a0), uint256(0x1a2c372beaa765a5c55b1ef72f90545553d93a4bf512fb0e3836513c072ee38e));
data[34] = Pairing.G1Point(uint256(0x1a7db24110b69cdc8439b2e0e037d987aa6c0ce89f7b2cf0318f2c8dde102715), uint256(0x008b16e1754dcaeeccd49a1029dd89fc8c93e6ce6a0581fbfd01d33177db4c73));
data[35] = Pairing.G1Point(uint256(0x268980a1f766e4119ac1489f6da7cfa2d586660865b1aee1b82948856790dd45), uint256(0x0e0b288f9de5568a1c757cbcefd912ea1d295ef472684ebf633621d9ec463a14));
data[36] = Pairing.G1Point(uint256(0x1a4db8649f6c80942c0922800bf2b94acca80910e11f1c8fae4237ed767b826b), uint256(0x0a3ea37301ea4ffac8197f5cdcb40d426d0cbe0b7783559a70c2eec17824bbdc));
data[37] = Pairing.G1Point(uint256(0x170db79c0aa72123e97a458deca8348b03c4406d2c37acc53eb824b3e0231d1a), uint256(0x1629d7e3a8ed5525efacb1f60991dac023f2545defb856e33290dc11c5b45496));
data[38] = Pairing.G1Point(uint256(0x0a0bc895dc51ee47f9c7e2ebd9fca3ce3c5451b68054081bf491435254aecbbf), uint256(0x0de0840f758a270cbf5dbc976e156692244f3744d2c093e7d6d340e20e1d18a9));
data[39] = Pairing.G1Point(uint256(0x06a7062f50a6b99c906a4a03ed4a0f1c319c68ddc1b95b13a75cb5eb713dc9f0), uint256(0x2c12b6c39101df58aaeacb6a06860d958a58afe74c2d711b4925528d2c5e6c2e));
data[40] = Pairing.G1Point(uint256(0x07ad65bf917cc53cfb807b12a1377d151267e8e3bbfe6781d7153e5df8ee92a5), uint256(0x2df03e25c22bea74b4c87a052c8957b98051ef443038b88dbefccd1995e73e1c));
data[41] = Pairing.G1Point(uint256(0x0dcb58165d4dfb3b158d41f2b4fd65c1a2dd134c9788a0b2c0cd333cdecf0baf), uint256(0x123a5836b7853bf27304f79c146d51edc6bfdce39dee9f5a9d7bd6b13e4d2951));
data[42] = Pairing.G1Point(uint256(0x13e6b0f62c9f333ac0fbfae24a0be9572523ab404518cc000e76e4fd3f7e8595), uint256(0x1cf2058b3cb9ee7629e7fbabfee4a331dc2b952cd5ad9a3e1c560701a29d62df));
data[43] = Pairing.G1Point(uint256(0x0bc7e262ad0022173ce5021041e6504e1ebb677a5de7fd1568b004d9cb12105e), uint256(0x213a4993cf1a4b00aee6a876eab7a5dc636e60568fdd75fea2c0c785c6228df2));
data[44] = Pairing.G1Point(uint256(0x0cf08483b80d0cab566ef15b88e931ca6ef26bbdb2bc4064f1faef5627ac1fd1), uint256(0x162709269ee7403505f94da07d41970306dd68e23b1dfa9327f584656abad888));
data[45] = Pairing.G1Point(uint256(0x1455d07bf27fd6458ab2ff3c13babb456a9d00b863e745516942a67c843cb441), uint256(0x1e029a2941765af40c0852c7843192a7975e6927b6012e803a4c60566d36b719));
data[46] = Pairing.G1Point(uint256(0x0a1daf5811a0aa203cc58a149de4f903a3bf056eddb1248fb1b67d552da95c97), uint256(0x2c1570b63e54def27efa7c4c2f0206c0e97abcf8a5d8f478e8b4e2d639e501ce));
data[47] = Pairing.G1Point(uint256(0x06348016cc2b4f75bcc1c72dfe682858b63d6df1f36f8f6d807a344edef8b7de), uint256(0x24e2695362b473f5fd45e061eedf7a4487f51ff77455b0564983cc2182340982));
data[48] = Pairing.G1Point(uint256(0x0a73b7b6c6283649cb4c8c722807696881703ff952c85a1d8c60750af594de5d), uint256(0x04658d3f298f49b0cd81da218e0e1a2a9675d00bc52d1f3833eeef8844dab244));
data[49] = Pairing.G1Point(uint256(0x236c48be622e8531a3aa5faf6cd1b67fbd525dc6b12e48c00ff676aebaa0dbca), uint256(0x297422c4c5960ada1a97b17572527d4652a63f3eb9f6d4160ef1d75353a21327));
data[50] = Pairing.G1Point(uint256(0x011cab4d359d75465dee2d259bad39b065a8cb54f25978eccc5b4e7138c5d4e8), uint256(0x101d3728de6cc2c84da7fb24732e57113bc50f642812c0fd45361a7e8cb36488));
data[51] = Pairing.G1Point(uint256(0x1701f3610c25337d9cec00ba45f59be839061d0f25c35956106093b0442faed9), uint256(0x1161b5d4d0f0a8bf0351c115af3a328c59c96136822e4c51c4972b8e571088c2));
data[52] = Pairing.G1Point(uint256(0x071a807f2603ae7bacfc1268855acb7b6f454263ba83cdb5b0a76cf9965ff803), uint256(0x218249969ebb27e7a6c9262a0a10454a82b8ff3992b1c928e687c7c8176ab972));
data[53] = Pairing.G1Point(uint256(0x09a181ec57a8393bf8052c09fda05926c4dcdfd6209de89d82629ac0f3b779b8), uint256(0x05eb1f9b09694ec6a5bd43c03b738d10f5a96d51d0a852dbe938bca53950f2a3));
data[54] = Pairing.G1Point(uint256(0x186f4ae1554eea6ee85ea25bd78d98fe4806ca438e4af2bedae03949cfedacba), uint256(0x10a7b484df3100de604c7b7e1821ea958268c228f233d9150ff5a983dd1a658e));
data[55] = Pairing.G1Point(uint256(0x1c4cf946dd225e2b9fd9d1b800d88f14fca8083f7701876b4b89feb453d38df1), uint256(0x0a41308f85d8c5b3c136b0dd49a15afb41a61b043ccf2f18074a4428dd8a0571));
data[56] = Pairing.G1Point(uint256(0x0afdce139856b4b8744fbd7f28ef6d2b3526168d1609783960fbcb4440f961e9), uint256(0x0e2e9056b31977022a88dcd0934bd65c01e63e2ebb3c92c4ac5bdb897532f44d));
data[57] = Pairing.G1Point(uint256(0x21b6ef5b6054dcede0b4f8e4a7ed32d1245d8d63d24eb7e65133b415d12cd912), uint256(0x0d053694f53d94d1b86dc30d8444e906677843cb98d60218c412e44b3d7e8b26));
data[58] = Pairing.G1Point(uint256(0x2f6499a6db022cd10ecd085a718749ed038780f6c5b78c655362cee9d30dae10), uint256(0x0ae35f5a58524c33051d92598f37f2b7993840bd70f7c5058dffa1710c947483));
data[59] = Pairing.G1Point(uint256(0x0dbea1e7b967cc06298aa4334d887eb844fcc9bd65e44c4bbafffedb0a73bd36), uint256(0x0b7098341f1cb219a9d7d93a7bc53d23eebd2316310d629df748d8a378fd1b33));
data[60] = Pairing.G1Point(uint256(0x29464ba12734822f7cb01c6e1148e073ac186dd24d33433e99dd4d498c9d7921), uint256(0x0d66377048ab551bd51a726e9f2509ce5fa8d22a048fbcb39eae57eba40c6879));
data[61] = Pairing.G1Point(uint256(0x0b5ca366a7c2ce2a8b786b393ab956d00f2f06afbde17e1e9f1535b287a1d141), uint256(0x043619c3408361b8d6ed1216fdad19b916d37ed935ed35c863fceb12aed8d526));
data[62] = Pairing.G1Point(uint256(0x06b2b22a459191872f46f6740334b240e3164e75d63ee86bd5684e637245a3b8), uint256(0x1c7acc0b041ba332c4f96281290aa145fb33960f1c708b122abc3dcfcb62606b));
data[63] = Pairing.G1Point(uint256(0x052760966e599a01d8e0ec36f1141c12c652990aa6866e04df9fe5092ac4029d), uint256(0x24b94a1eed512b8de9b6edd2d5041a3a254e0a5ae72887e824922a8165af9e08));
data[64] = Pairing.G1Point(uint256(0x25bf96375ae8f27ba7565100a345d4cc428dd3f4768a65dfb7a3a4919a94b547), uint256(0x07066be8225c65ed34b8a42a5af70f59836aa1d918042393d9054afc8bd3341e));
data[65] = Pairing.G1Point(uint256(0x1069072cdaca6bc5ab36baccb6fd760e7d444253c5929389f45ae6a26b4b3de9), uint256(0x1c4e3e2dd56c66e062107de17f73ed64855d2d34d21840d6f2ed8c9610b913ca));
data[66] = Pairing.G1Point(uint256(0x283dd305b7db1441cea77e32783af1f80376ad37883b5cf5cb60e8065857c177), uint256(0x20c21610bed1fabc619989cff2fb450c8b32e3b3484ee001fdfd2c1885d801d0));
data[67] = Pairing.G1Point(uint256(0x10b73b208d2f86a26eabcc4780974eeffc2b53d4a77572dfec71dc9b71e081dc), uint256(0x23397b4c549e660a055598241cb9a0405cc793c5e94c4161b2aaaff5745552eb));
data[68] = Pairing.G1Point(uint256(0x0bb2555a0571abc17ab57444cf2a96c428ff95ec541fad956955d89b0d207a12), uint256(0x12111591aa020b886acfa0c9c6d877225a8b34bfb0e0e1dc0e1bcaf7f9bd613f));
data[69] = Pairing.G1Point(uint256(0x28cdc4eb6bd0ee5774edbcfcfcf65e72a9da9cdeba0842bab4e3ecfbd13b3623), uint256(0x2d6cc5fc38e1dde0f9c3aa5bb90fdb66dddf79f8f932612c14a8805fd84cd7be));
data[70] = Pairing.G1Point(uint256(0x2b969bd70d791aba8369f281326a5f7c92393735a09ff6472c221ad0872c25cd), uint256(0x0873e980cf9d6cfcb6d6bc87e4aeeccd222d479f85977dc262cdd4d10bc28c84));
data[71] = Pairing.G1Point(uint256(0x16bf6ba8ff9dc23f84a9c8f489b5915ef48fc4b8fa79889e01dd1e04645eeb59), uint256(0x1b030065c8aa102ab8ffebb95ce0dafb0652410f0c726e230dd889df4a153686));
data[72] = Pairing.G1Point(uint256(0x197654872c92f4473106b3e1f5f21ebf60dbe865bfe6590649e83f3aebb1f074), uint256(0x16fdb2bd87e69a72b8a6bb56b30c604e4868c4b115fe0f401b4e210ce9a98bd7));
data[73] = Pairing.G1Point(uint256(0x28b25875e9c823d15ad0f1bddea96175f5cc98d966cf1e993dad9a2b12ed73d6), uint256(0x172365b6f5a4d3c6e269bf19b33ab21201aff592ee117e1b1d6a9fb3efb70d19));
data[74] = Pairing.G1Point(uint256(0x1140198795d2ea5e170e6d01ee2ab7cd6c522d066d223b1b285ae92b614dde8d), uint256(0x14714046077a31cc4de08307794c3dd95663c7df605b97f29b9b10457cd8e506));
data[75] = Pairing.G1Point(uint256(0x188514709d92425f13116bdea3aa191397c6cef21644ee7f1a3128f981c73beb), uint256(0x29ed13cf35160c59a789e872eecf76f180543f1ff8ba2b456c378e841a4d0483));
data[76] = Pairing.G1Point(uint256(0x138377c6b2705de8c3fc0ebd9d6302716de0c0a1a4d7dc33057cf5c5a0512ec6), uint256(0x19ec8d951209742027d8dede954305eefc3d7bdbcc54be08fa89fc0a5132f0fc));
data[77] = Pairing.G1Point(uint256(0x1923e49b25293e790ed2f0ddc034138a9ce25389ce02b5ec4103c1c2c32b0c30), uint256(0x10c54442b6ab44283894767faaa601306de7de22fcf6335e4150f102ce77459f));
data[78] = Pairing.G1Point(uint256(0x0a75a6ef08578cc0253e93d3e3c8bc2614b8acbcc81d11f9cd74c3a8a9f8cd11), uint256(0x0f809782fc1c093f60691b3906eb92b78ffc1a1aa8f8f2db04d0a1f9cb04ce4e));
data[79] = Pairing.G1Point(uint256(0x2ad5a95e45b06036153b19c1a0836d41b6ca2cd07e8594e439f23dcd6b50ca1d), uint256(0x007e5a97b90d7f12dfe7b3921453bb53fa855a5f9a75aaa79fc74c7fac9d202c));
data[80] = Pairing.G1Point(uint256(0x00b96aedd43989454cfa6fa59cb518a4bfe8b23645b2854c4e5fb303d61a8594), uint256(0x067513462bc8f0163df2c02ef8a6ea8b4dbb5663ce3d19455e40f6edf5bacb8e));
data[81] = Pairing.G1Point(uint256(0x30175f284c96699adac1e85f5a2b0c91195a6e7238db909f919957fc385b294c), uint256(0x05710fe7a8a54a22c7639ecc35a4fae3b9b2c0fa35b9f0f0779f49a34dfd1a07));
data[82] = Pairing.G1Point(uint256(0x2d7de32f99f04be705a26f4e8ec2465d093d7932aebdba2e6fd9ae5cad356b6d), uint256(0x2aa8322f33a5b92d177077e8d4bd9a2cc9654e560127311d7ba443f916570c65));
data[83] = Pairing.G1Point(uint256(0x0edfaf0d22e151b7fd582bd8fe8cc0f978d3bfd0da1f246ac7893c25066d32ca), uint256(0x02c69ba65d2a61ba8e0a0fdd11879b89c9642ec3d685cfebc892c2074cae97fd));
data[84] = Pairing.G1Point(uint256(0x26e76a6cfdad3989e16ab188c7f423fd0355129502ee77fdc011cfca42c85353), uint256(0x112fbcdce37d374b6e6dc12440c4262f48e90bbd1e22edf9dbce3592f667ebd2));
data[85] = Pairing.G1Point(uint256(0x240e8e21d40ec02e34cadb732555d0e7dc0fe57f5d7ae4c25f4b3ae3ee61b467), uint256(0x27da67200aca87688d47b337ebe0fbd8d7dbfdedd04c8914d28788105da8fc0f));
data[86] = Pairing.G1Point(uint256(0x1c4c395c3ea5351cea7f0e62c071b4a648389590da5cdb923f72be8ec4275304), uint256(0x24388381b5408beea2e316ae0717ebbe4ccecdb983945dfa76e66e4147095153));
data[87] = Pairing.G1Point(uint256(0x1626ff25e117552298e578275c18922e26270cc3a9b0965bb157dda0a04475e6), uint256(0x1b1e8c67623b200c1693776f782003c21059d1a212b031e3c63b9c774c72c0b0));
data[88] = Pairing.G1Point(uint256(0x1053bc5eccc02322af31fc90c471fcbd7168f6efcc9e8f3ddd8472da2c77f789), uint256(0x2205d135ee701360431de11e5b8dd1d99aff33ccde02c2b71dbac793c884da82));
data[89] = Pairing.G1Point(uint256(0x09dd709e4d4d68b45f528e39266f3be0a707afc4a29d9d97f818f0b0f401712f), uint256(0x29a63b9822e00403319938006ca2428684989fda4ccf6b98f347d80bcca286bf));
data[90] = Pairing.G1Point(uint256(0x0aa1d5f85a5ccaa1fa2037baea79299c8071dfd208ab40f64f5f2d92a90f30ee), uint256(0x143d41fd7537ea57a38c52f09f32686acd5f0daf912f32d8cf193b61456e0d3b));
data[91] = Pairing.G1Point(uint256(0x24218ce78ec0a3536abde8e8fbd05784e32b2199ddc13a21603ba98e257c418e), uint256(0x06f5e27abff2811b46a9ea3272afe5b7d796e8ef63c63ab2d89c659a59b3fde8));
data[92] = Pairing.G1Point(uint256(0x2cdfa5cc7ba87c21d02e66849a214dd6cdfdb2fcd041b9a58d2e07296e3d4342), uint256(0x05c8cd2672cef9836a4c800573bd03f687ac19fb40b96de375799b8e8620f47e));
data[93] = Pairing.G1Point(uint256(0x23109e8dd9eeb0cf42410b2f492a6dec2b84b197fb7da26fc01d132e4d7004a2), uint256(0x19366a2a312b5bb9323acf540000abb94efa5974739ffc5151e7a6dec04eb038));
data[94] = Pairing.G1Point(uint256(0x2a2ce1444f3a41dd396af349e00695804e75b29a1738157d2c4dce60aef37515), uint256(0x28ff25db8ee3fe41c5f3790f0961a5b9b2a4c098953b319247a9a0230dad7c47));
data[95] = Pairing.G1Point(uint256(0x2ec4600a106d909c653b298235d10edd597d5cba9616480f6fcd1640853b975e), uint256(0x0a6c00917b807855eb0ea04bc2d6f99dd7c48bf9475ccb10613a964d4e31da7c));
data[96] = Pairing.G1Point(uint256(0x1fc61304ffa2d354478dd08a9fb3a6d454550612c9f4288a51e74568cddf18b5), uint256(0x0eb7af57e8943b0476c26be65e4f3af9e9ad276c4b550b2025920f2e20a9003c));
data[97] = Pairing.G1Point(uint256(0x15a4ca746930f08f8f854a90e3cec8759f0a32b0a3f0e615d1217c5394b21a6c), uint256(0x0dbccc64421475d6ea50b835e9d7646f10b2d9e26d1f83487658e3737c446faa));
data[98] = Pairing.G1Point(uint256(0x0a67ff6640910d7921ceb0b58d452701fa16c6386ac00900aa399d0b5606e8dd), uint256(0x22acb7e0d74328cac7369236cf1930ad57848429a13366d0380f2d25b7758a03));
data[99] = Pairing.G1Point(uint256(0x277969ca751b40a2376e1a30e96684014f85f2f565214d1c277585bd13c0d3b1), uint256(0x0d3dd4a5de190d5c2fbc3e129223c42dc3d2476713d5766b516d03b960c81190));
data[100] = Pairing.G1Point(uint256(0x09296459dffe8a2b28b3fa881793e11a16bb21d66581ac34024a0614f8bd6129), uint256(0x0acf53a7a0943691a76861478c0242c4fe9e67dae857adf050b94f8a7d0c5ad0));
data[101] = Pairing.G1Point(uint256(0x14af692408beefdec0d8a89f4667b2d37a950aa36fc67477dd568f8e11c280b8), uint256(0x2c17860843da4a12e399e350d55a224e0d2c8a741e99be6afe52f6cf24f8761c));
data[102] = Pairing.G1Point(uint256(0x292bc39019323dcf325787786cccf082c65cc833bcbae700d92990b0fffc8624), uint256(0x0b5177c51f1a1fd060702decad0bbe778b6e631d2d559ef018e83a1cabda7e5f));
data[103] = Pairing.G1Point(uint256(0x084d7f10839196ec44b5f053c0fdb8884abc699f70295286a602f707f6dc06d2), uint256(0x1c09ed8399cd758a29d2a2f96f42661c960c1215cb0f212803c6a935b792a930));
data[104] = Pairing.G1Point(uint256(0x12038ae1ae43bf5fdb19b9d600064dd961fe1087f6f7d3c925ee5d591ce05a45), uint256(0x29102b7387825dc9c0529fb6a618f1eb920f5a82749a5a830425279211566f0f));
data[105] = Pairing.G1Point(uint256(0x0fff80441c902b0b2b1f71663ccd04ecb81ab23c4ea1b4a8414c58d6ca7c2bc8), uint256(0x18b231823e32d3c189523a1ca2e45912bd0743b346d56df2f56b66c00b7aae9f));
data[106] = Pairing.G1Point(uint256(0x254089da6f2edf0646de4f55ce730a1f56150e7c033de95cd48e1c21bf2a9845), uint256(0x0cf628e24c02e4e79731c0fe0de0e45ce3945042183646eee8cc3e7440b5a436));
data[107] = Pairing.G1Point(uint256(0x11c4a5e22fb63909499515a61d5712ef64870972e55daccdff76d5f6b4b77934), uint256(0x2eede9399ff61810c196a3075c8bb9ce871a70ed4c05a3935744bb4fe4aa9b4b));
data[108] = Pairing.G1Point(uint256(0x17dacfc19d3e49eb175005825dac9da6999d61fd41a4390c42f2acbe01f4d648), uint256(0x2b1d52684a7becae4850f7b558f903cf35b9e2167c3fed31060c92ca7c2c7719));
data[109] = Pairing.G1Point(uint256(0x2e4a79e34dc78e79ff8fe60db04b2b9585b92a8a62b2d7f57abbb39a47ef266f), uint256(0x12100ec460a67600b0474294d00073b392434119c1ffa8526751bd2e72b83284));
data[110] = Pairing.G1Point(uint256(0x0877839625402b3181e8b20443390ff0dc72493379adb18e144aadd289840840), uint256(0x138875c1306032fb840d6a496ad2f6c5e539beea453d60924408987609960a57));
data[111] = Pairing.G1Point(uint256(0x2b8fd5cf563931bfc280029ff77227b23b768201ab12f34aeb0016c44322cf5b), uint256(0x2e2d7abfc7c350046bc67da57006996edff640d0ee1ae5f8bd05275b10a65d24));
data[112] = Pairing.G1Point(uint256(0x198576497778769ba786f7704c887c2dc4fb06b6e4874d792632c1087ebf1b2b), uint256(0x1817cd7f7fc25db95fed984380765f2a9d0aa0bd6b6a7254cb2832614d9d26fc));
data[113] = Pairing.G1Point(uint256(0x172f677ecda7505297806a8fd4b672df3e8a295771cc67a1fba70572320711fe), uint256(0x074d0f60cc82a851e440934eaa425ed83ea83c214dc5ead41e62268f3ac9af0d));
data[114] = Pairing.G1Point(uint256(0x10917b12288bb0dba26084ad5dc6f6782b3e88082ae617a223472a670c03473a), uint256(0x250580d958161165fbcab515d562b2627822b3f99abca34ea14c56b8d464d609));
data[115] = Pairing.G1Point(uint256(0x0faf180b7eacfa697868ff0821f27e9cfd4b7cefb9e68b626d331d920ffb8502), uint256(0x2cdbad2717cb8abdad09a527215d3cef3ea4deed88b94ff32008f780bc6abfac));
data[116] = Pairing.G1Point(uint256(0x10ef9bf95082182d2301ee053d0f86b7a7d3552910b1793e9f0e1806938b6802), uint256(0x15db40bcb73c18f4ff083a85224a926380858f7382c6a083577efdc5d671cac3));
data[117] = Pairing.G1Point(uint256(0x1cc3e74fe5c4d90ba565bc4a8d7f0188d3646c24722c5af7f85dafddbba7e4b5), uint256(0x0c8665ff2ca4de7287e5c7b73a3226576c5e4fb5f07bb657d9c47b7e1a24953a));
data[118] = Pairing.G1Point(uint256(0x1acbb98192cc4b45cf745f10387951a0fa3c851303f1566042f1ba0d8a88cf20), uint256(0x196f02ca614ff46af0d3e454b6bb4c19a07f8d785abee2bda2dc38da2b2eb1e3));
data[119] = Pairing.G1Point(uint256(0x2b0db7ca4240cd8600eda65c58606183b7e41f09cf8ac58d7399c31c993be014), uint256(0x06f100c281866789e52ca4d6bccc300c97ad855ba542c6ffb12cc93f4b63fe86));
data[120] = Pairing.G1Point(uint256(0x0182a82b24b92807ca79eaa0de8bac2d770000c11db56dc725b317844ce565ee), uint256(0x0edf6330496345ffc59f0cff01fb41d16e6f8b819f4e086dccf340578b751828));
data[121] = Pairing.G1Point(uint256(0x08db7524957818c71a1444d037145e51c1e49be00f209e1e4a8bbe8ace365e4a), uint256(0x21e4fb91a7e33c121c93e1479b0a660fcfa6c9bbbba703d986c26de4f04f5532));
data[122] = Pairing.G1Point(uint256(0x0b7efd7c7c0cff0b9428c2308e104b3bd81e9f7e17be34edfcee78895af7527b), uint256(0x21a84f37cca53515171c6a865c69f9316c54aab8c4a2f76dc217a28974c76a40));
data[123] = Pairing.G1Point(uint256(0x05ffb1aba6048fc0f004aaf7e6196fe976dc6d174c6cc741560ae145091d1888), uint256(0x25ca4a9459b4c5a34069dfd81ffee6943ce7f7affca7639572c5a98e6cb49717));
data[124] = Pairing.G1Point(uint256(0x0c30ba96687da3fcac93f118ba152fbbfc4ab6e5e382b25b05c9633df4a6ebca), uint256(0x072e2026049dcb0151b10f48db6621bea25f315ac417620502da1d5b7c90fabb));
data[125] = Pairing.G1Point(uint256(0x1152d0888a99c4b9e0c622cbc02ec7acf1c1990f24653bd9625208762600dc2b), uint256(0x1bb574b4515e83cbe9b40eb8e6fb21d04d8af7620e3749f39ca704c45cb62760));
data[126] = Pairing.G1Point(uint256(0x2a74cd849358f0aac851e8882a60853b57ca378a5f498f559cedb58bbee436ba), uint256(0x219c5986d0a2564cc848202298c16dba2d2bf230c1c884c6dd6a9d5c9829c516));
data[127] = Pairing.G1Point(uint256(0x1e9c5adf19688a2701432fdd272f5698e2d38f962044ba9495263fc3269404ad), uint256(0x2bd739baffafb03e84bbec4c59e5a6eb5e913329bd49946b2d3e23bf8125958d));
data[128] = Pairing.G1Point(uint256(0x05f4b52dbbd1f28ae97ace9bb04300023f720e02608bb860da8283d6f5288113), uint256(0x21e5b8fedfa4081d4540bbef8fe7d7dbcc23a3d0e0f92f0ad005060280c37814));
data[129] = Pairing.G1Point(uint256(0x18a22b2041d5a11f8a7bbc34d06f09922130d9e6355772fd6ac1689f46d316da), uint256(0x22908521a58257dd3808c7a5674dbc54dae60ba53c59c6424483af07ca96a624));
data[130] = Pairing.G1Point(uint256(0x2d11f21a9656c3940255dc9661d37e74ee3d5928ff4a63f9899bfb688ea9c142), uint256(0x13be681b84e2947438d4f5751a24c6b1e5e0e18d0af8be1813e8da29559cce5c));
data[131] = Pairing.G1Point(uint256(0x197c9e42d9cd26605467b76de63e0c32253353f4e0b4e60575b1a36cb3147ad4), uint256(0x2e7d0f5ef960c808c04f6a33a96c2675ce4d837ba6c8c72930eb9efa4ed826cd));
data[132] = Pairing.G1Point(uint256(0x18e848a3f723d9359baeba3641071a83ad3aec3167cbd064539f2dec1fe2150d), uint256(0x003e7d86d3400847809f54b142b78e83675ebaafcb8420de523b01ffbd52aa74));
data[133] = Pairing.G1Point(uint256(0x1195b025a80d15a2f8922edcbb140f9fb8713f6e6890b2f72437db14d772e9fc), uint256(0x230f61de98b1d6585f487a4692d1437b5e81a60c1d3cc11f61c44d6ec8d320b9));
data[134] = Pairing.G1Point(uint256(0x01fdf42a6077ec18f849b73d96faa84ae702e8ecccd41e1bbfb9e1a4bd5b3b19), uint256(0x29fbf5b37b06023fc74f1d63dcd6903e3b9a701d49a233ba72fa80dd8cc19efa));
data[135] = Pairing.G1Point(uint256(0x14d1fdc8db78d35450645f3b2ec40c8ccb101b03a14510f8b148060f4ffb6d67), uint256(0x0d11c73bf121614e3ec9e32bfbebae5769e0a7236f0161d710666d264c6d356f));
data[136] = Pairing.G1Point(uint256(0x2495dc806625df44be4433e612b721f89d4fe36256f9c70753c481616fa24329), uint256(0x107dbd8314c0e311bbf985e582fcf12c1704d2e0a099e76b156f70bb707f2247));
data[137] = Pairing.G1Point(uint256(0x19618d3229d13eba8cf9b620948ce4721fe86adf13f36e197c7da32c892fde41), uint256(0x0a162d2163e4b3a14ca096cf3e7a8b8e3e63080b7f8e14e6f44cc80c7acdf790));
data[138] = Pairing.G1Point(uint256(0x02ec86d7eb8eb6dc99876da439671e3dcd7d22bc94cdd0dc503265fc49c89c77), uint256(0x2fd7267721964480096310e5fe297297be51580462e0e03a56bb34f9b70f7923));
data[139] = Pairing.G1Point(uint256(0x173314c990770872eb04ec4449176b15e2e76dbec66a3ef4875dc492a28b0eb4), uint256(0x0fdda43ffa9773051e18b5a29184a362bbe20cc4b711f41e78ef73334dec4ade));
data[140] = Pairing.G1Point(uint256(0x11c583f2c5800c2e6a6b97e48739f000efa896174fdd21fbd588a40f5c3a194e), uint256(0x148562062d94bc594db8bd2754cae0cc4b8ce3bad2b07d84613ccfaea4f91f1b));
data[141] = Pairing.G1Point(uint256(0x08b9581f802e27cf408e4a76bd072f50c9f913be8ecf8b22c45656fcb07af437), uint256(0x0edc246d13e72bf3db337d295302741315e0ec2772effa615c9c50b87ac77e02));
data[142] = Pairing.G1Point(uint256(0x2442bc4f4ba530d375b4226e7c30b9b46dc9ac5c72cf6a98a58f853d958d860d), uint256(0x0ef74ff3651bd1b77e0819196823e3ca89c6847150bd83ab18f5b89210f40a39));
data[143] = Pairing.G1Point(uint256(0x29d6a4ee832f27d7dccb3fca5fa3b774b66c66bc967ddb2f26d396f5d831f997), uint256(0x254cc9ceabe29676445494fe70b1c998b31e08079d57db43dc7c090884ac7baa));
data[144] = Pairing.G1Point(uint256(0x08c664a6fc481d2b07a69c985c0273212fa2003c84bcdd6f69a8ed5b22d455d6), uint256(0x002e68ffe28676125e73167e94d1ff6d345be821639cab26781d11d4c0b03863));
data[145] = Pairing.G1Point(uint256(0x2f3e9fcd8c16bf4abd9a239ece08691ccd5258935e65e3ff169d0981dee95d07), uint256(0x2ae826804285c55c024873e78b6419d31f4aa51cd779a481ef37eaa93064cbf4));
data[146] = Pairing.G1Point(uint256(0x13ed92416884056265ce6cd4dd43c32af312f5f444b14e6dcfbc1c4783626ced), uint256(0x0627829c20089d229e011a55424e0a9fb0f8c677085f1555fb49889cd853e5f1));
data[147] = Pairing.G1Point(uint256(0x055499ce947c888d769b1719eea98223542c56ceafd96726cdea55a3104ce04a), uint256(0x036ad65f9dcfa4975decfb8699fb4469fb3d6c5063412ef36c6a82a8510eb96e));
data[148] = Pairing.G1Point(uint256(0x24b01dcf6f0f9057fe99ded9d441eaae2b9ebff35b847f7d25ec9cd33cf904c8), uint256(0x22a92099d7bdd9d0a820e148244b156d7ec33e76fd641a0e9379c6311c964595));
data[149] = Pairing.G1Point(uint256(0x079151f360df59d15043e57c6746b3d89e49ce7067acd00227beea24a19b4e51), uint256(0x237fdba9b2384958b90dc3f56338c49edf5ceb3254a12cf4ad0e9a037b985347));
data[150] = Pairing.G1Point(uint256(0x1c94fc97dd6d51f1b1cfa9afa4d6ee37f8b4769e43a85faf4ed9cffd1be570bd), uint256(0x1a5418127fdbe9c8396e91765e933fe710d6203d5a342789fe70f0888470bdb0));
data[151] = Pairing.G1Point(uint256(0x178da25dba8833284ea9119a998678551424cf5c6f445a83a79b699610e0cb8a), uint256(0x2e2687d299873e23be92df89d5eebf3ecaa10fc88cd72a952e44de99989e559b));
data[152] = Pairing.G1Point(uint256(0x1176ab6efbf2c4fdeb5cbecebe3a5fee5bb1e873dbe5c1bcf5a666a18212597d), uint256(0x249f45c01fdc9bce1fa400ab9b2572580022a577206b5a3146d33fce03ab9212));
data[153] = Pairing.G1Point(uint256(0x145f8a7bc655a05508415f34a68ddf6575b937fae2497beb30b3a9bdb8e38b62), uint256(0x19a949015613f004624b6ec442514e173e285acfb7a98997c50de3bbe133865e));
data[154] = Pairing.G1Point(uint256(0x0bc68ca7d5d3d3dc7b0e6a82d0d3bef6cfc582e95dc5c5a1e943baa19747c5c2), uint256(0x27f065660cde229b93b88b80806bfd34002a586dc53843194a7aa18345c2512e));
data[155] = Pairing.G1Point(uint256(0x12bc739e847f747e958fdc7d3dbbe97651011deed8499bacbdaa850931f711c5), uint256(0x275b76b693c7404e51884c44ff5404a65c78ca24ea09097c50dc5fed79d8797c));
data[156] = Pairing.G1Point(uint256(0x010e312789e234147024f41350586941ec6595d199944e82ffaa06c5664fc230), uint256(0x2f85be24a090c2fef06e39a8f2c1db203f40a24a7b44bf5ee7616c595cdd5bd7));
data[157] = Pairing.G1Point(uint256(0x0ac3d80492b5d03944f07ff58dada7525b4bf4b3a4dd76ef2385f6e7691ddfd7), uint256(0x07304aff4c3f8f68e151ccc808c537971866e30cabade17ff5d00a3acb5a3fe1));
data[158] = Pairing.G1Point(uint256(0x01d0dc011e05dbfbc166e0a6a24f5d8647bc3b51900282ccb944d972471d8428), uint256(0x2f7a2a79f9fbdb120215ad525bd5f9da58d6f3d10bc9e2f71e95b65107b55f84));
data[159] = Pairing.G1Point(uint256(0x1650c3b35a4e2f5fcc17a79fe5cc9ffa9f82ebb2154d694f979e3cb2ff6cca1f), uint256(0x0f533bfd322ec6dec4a53b9c5e7ae1cf7e7954dab6702847a2b9d85b9759a36f));
data[160] = Pairing.G1Point(uint256(0x18946455d7699da11cbceb049e7319e7b5d492a98b45583dc5b2c0b455f2806e), uint256(0x299a35375be7021738813ace5eef26e193fe43d8889337d261f4cfe0b631e37e));
data[161] = Pairing.G1Point(uint256(0x1219f5990e7580431248386f4f2b2c8557c51d9f5dcf859f8777f3acf250e6ee), uint256(0x2cf85f82bcfdfd09906b10657e8c1230c432cbab51539ea7022fa1f453a6ea1c));
data[162] = Pairing.G1Point(uint256(0x09c28256e06d64a01383453fb822e99eb2a455e78da210801976d9207951b997), uint256(0x299ebdc236e284198e1fcff2da88e08fd8c5d3d2daff4647312029011d5c7588));
data[163] = Pairing.G1Point(uint256(0x020477301a1ab39a1f50ee19343d31082c07a68894e581cedaa7f33ec7a67a48), uint256(0x1d79bfb69656b230bc27e4307097a2a5f730336a665ecfb8eec9caa246b1ebbc));
data[164] = Pairing.G1Point(uint256(0x18e9fff225fe13dafd36dfb1c0723399a785ed2ab0232dd206c3ec0221b3f5f6), uint256(0x1fd8d49dcfff2ac1c97a5d1dcfbb9d27019a3c61c6fdd2bb6ed1d3e317c07f6e));
data[165] = Pairing.G1Point(uint256(0x03ea62865f567268545156b749cba99077245e5b38ecb06d4a18c4212ba5a532), uint256(0x2192d690a8bfe6cbd6304eac6df368db7bb53286469d3638e9abc767b7e4232b));
data[166] = Pairing.G1Point(uint256(0x007b0b27dc537991d147399f70c51c590a767fbb46fadc0720e18ccd999d208a), uint256(0x2295455230fef44a024d2560575090c1b708e5ec960980bfd952e9c5faceb65a));
data[167] = Pairing.G1Point(uint256(0x2f3c7d9c0e34fb64e30a60ff3d02445d4efccc5c0d4e28d4d15ab3429b8caffa), uint256(0x2d9c40d37998bcd10b86ea5a7df5100d11d79f039962e36cd1ca25a4f43f12c3));
data[168] = Pairing.G1Point(uint256(0x13926f998ad05e8ddbda7407ae36b735b39e17bf7c37b18b888e004ba9805a3e), uint256(0x2bb97c06d43706344c26b9bf854d6bdfdd8ddfdb8dbb8b9deba89c05f20a81ae));
data[169] = Pairing.G1Point(uint256(0x1b5407428b211470dd993ee010ff21cfbf5ab0d1cef69b45ce7e94f9005cd179), uint256(0x0091d66fea03ecfdb0e7327e9bd3da7933acc4d23d233d7f0f0dd9598e43818c));
data[170] = Pairing.G1Point(uint256(0x224e8e6377ee7d123147b4a36634508bf483e53a0a3c31f647f681cca0358c11), uint256(0x0c8a197723675fd6d405fd233e8e58e984d2915ca4d4d89f3d4fee9264bca0c6));
data[171] = Pairing.G1Point(uint256(0x2ce3310517250d6fd504afdfdf31847417fae36c16551845b9fce124be8af470), uint256(0x10cef29ceccb432d66013d51a0e15280dd7d381d2c9281e1376e2609a2b56e0a));
data[172] = Pairing.G1Point(uint256(0x2b4e987d359136d567f2a863853d48e31ad3c6b6a53bc48efe8b12a8ddf142fb), uint256(0x2754090e9b1e61092d6568938550986803a42d064a0bdd0ebc377298a6cd88b3));
data[173] = Pairing.G1Point(uint256(0x260f9ee149d17a358887eb018c775d3789333a0a46ebd8d83d042549cd0ed12e), uint256(0x084c1efdfd149b76fb10b3660de809ef29efd338f09fec8c77150adf512ebe74));
data[174] = Pairing.G1Point(uint256(0x26bb41f26d8b31711f1244197a855c69f60abdc1d63a8eacecc7b366a69f4e96), uint256(0x2f6e94c9db0697e412aee9c30d712e36ce502e51c15ab8b5a8acb0027f2ce583));
data[175] = Pairing.G1Point(uint256(0x063613fdaea64140dfb1db6c556c6d88d40583be27ea66ac2d0d61e9d391695e), uint256(0x273bb82bdac003ad66f18a6f00bd1761d822e78af22a015ce0b906bcfc58f57e));
data[176] = Pairing.G1Point(uint256(0x045d730d22c5f7a3b2aefdd47d9d88e5a53b1536d4173d5212d6c3619978caf3), uint256(0x0cd2a1bafcba952c6bc54579fa34e9f77f50f33b71bec67c277bbcb04f40ac9b));
data[177] = Pairing.G1Point(uint256(0x08fc581afe9b2cb98066ff0980af6799fcfaf4d05b4f9c666eaf1e87117ffc88), uint256(0x20be3abe28eec37c825bee6241e76fd15877c07e2b6c41bc743eff6dc2d2d831));
data[178] = Pairing.G1Point(uint256(0x2c9cb687f70aed7286bb5047bf37ae0cf28c7e84559d70a200a8f145e6cc1f1c), uint256(0x0b44527637cb0caa6e77e18775f695417929e5fb8ec9a8a7d169679d84f26e7d));
data[179] = Pairing.G1Point(uint256(0x2aec430473ff7d0c3261a787e5baa37d41710bfadc7e6fdd568e31f39b66c9e5), uint256(0x0d565bd6b71dd50b1f3601a41248fa135283aaabdfdae2ac537af0d607bf0588));
data[180] = Pairing.G1Point(uint256(0x26a24480a5743b84bcf195839ceb29463a5436b7429186e91c61c4f60b8ad6de), uint256(0x0c76d60bc7d497c21e2fae5c0c02c67b28cf34488948b1310eb9fe098fdfc989));
data[181] = Pairing.G1Point(uint256(0x22571fad920c9844fef4739b14a25334efa67457c99ebe607c49f91196f6038f), uint256(0x28c8876438855d90931e11df37aa3933c2457ff74ab0470f3df9662849f1db8e));
data[182] = Pairing.G1Point(uint256(0x1d9446b84283a88ec26f094b5683087224f438e1cfce4c98a0370d7b817c3df1), uint256(0x0fad977303398cf37d7909e09113df3d6fe129d279f70ae4a4b9017123ac7a18));
data[183] = Pairing.G1Point(uint256(0x2d2d1ed457e7714acd13d9f9cd1b4eb0b4ec8875e8fa0fbe5263ceb23299ba3c), uint256(0x10f735ddcff981201b0d4e5b44698123382a0788899d0406bc88ee688d2ad2b8));
data[184] = Pairing.G1Point(uint256(0x092d3af2064ca7a70cbdd6acf388f329ca71ada948d7c70b45b38f2849024e10), uint256(0x239c9f1e95b9a609c79c0fceeaa461c0103ce626a6309851da496e63d3b7d26a));
data[185] = Pairing.G1Point(uint256(0x075f0ee0f8f18c6b1040c9eaf67b414db468591c34d101eb3feac4dce941b724), uint256(0x0ba5d8896793e6ce42fdb95fde58efea15e35cbbc7a0c6b625a9eff7da6e0713));
data[186] = Pairing.G1Point(uint256(0x104e9943d012f521cd70261b1afc96393993e893f2fa99df2a79c6d61735eb95), uint256(0x138cd91f41f91afbc6e01c20bc42a2a67d6f8a6e955bec82bf3b0f0a1f94b9aa));
data[187] = Pairing.G1Point(uint256(0x168bb4f16f9ff01b716f2db10ff55eefef475693bc55d5fb7cb6414bb2bb5b2e), uint256(0x2c003161e85bb155f009fdcd1da8c87dd8eb3becbf1cd3ad2b798add0f6e143d));
data[188] = Pairing.G1Point(uint256(0x2fe60c317be47f89cd2259291fbee22fdb9c86aac96b899e83d0779b4365797b), uint256(0x0124930cb49a50d77675d3e227f54451b7c271ef067794516edbf97a8f6fe787));
data[189] = Pairing.G1Point(uint256(0x2b18b7d14cf34a7690b972514f9af22d8e1420cad8a02af96c53407dab1047d3), uint256(0x07d68676459cbc5136cfb41436394ce19dd867178fbd4066c15d916f9c41c62e));
data[190] = Pairing.G1Point(uint256(0x1cf6d90bd153f1eae1e500dc24f5f6e90ccd8a12731c0111ca531bfa6ab9871d), uint256(0x07ee18ebc189d83f41453a5472ca2514ea608c38a7501f7aad0864ae8f9cf88d));
data[191] = Pairing.G1Point(uint256(0x0b43e755419eeff83de77ac263c2c64aab9bdb2d7b8e87c10dfe39dcd3b8e18e), uint256(0x0255d88bb64c0aeae08f7346e96aa90b86785bcaed1c5a684b9e05cd24510988));
data[192] = Pairing.G1Point(uint256(0x27ab105a651833cc2e42f44af479c56ac3e060f8e107bc2c2aecffae11ad2f30), uint256(0x02e540d05e6b2a89ba2631d985f1fe598beb2a35ac690823b8a579fbf1f13273));
data[193] = Pairing.G1Point(uint256(0x01556f2e53036c74e5748350a5e9e777d247b7bbb744915dac8c238eaf14a31f), uint256(0x200e9f4b0fb63aa16de0403573abcc8f5306156607da5a2a8df39b0ea6afa8d2));
data[194] = Pairing.G1Point(uint256(0x29b157c4930c15261932a8f02b6b26e747691d2bece2ea716dd048d2428f3a81), uint256(0x14c4478f9142dd871590612c7807f8612cc6f6e02d1b50f16dd6ce5d1c27b089));
data[195] = Pairing.G1Point(uint256(0x2a632f1cd5fc5c6e539f55f1e6dabbdaaed524df64c24f3e56702bb717c84795), uint256(0x044dfc4c8b6f5d931d2f94d52cef3d3598e65dcaefdf994aa5963848d973a860));
data[196] = Pairing.G1Point(uint256(0x29cef9629277895108cd04a1a6bd542e4850fc2e619784069300c7a6e7baf304), uint256(0x186d63afccb350ed1167a7708ffc5b658f57e008b8cc080f6941efd6e8abd9c1));
data[197] = Pairing.G1Point(uint256(0x061ad1771a419daee85a3c50cad9fe2cc003d128af37d4f4ca984a6943254f00), uint256(0x1118100e6fe8a7f3ecc5bbd243c7636811b411aaacda4fe5d3dbb5a14d36e2f2));
data[198] = Pairing.G1Point(uint256(0x0d663013bc2646d3386f70831a5857bf6cd55382a0bc9d02d87929a2fc6d8cac), uint256(0x1142f1b9da269f59e78634af4db6e1925a739ebdf396ed6492a270e01afc0b95));
data[199] = Pairing.G1Point(uint256(0x1b8099b270a4d23cc4cfabfdf3eaf488a466c7e70f026161c7c7320a3fe0169a), uint256(0x1e96fd55fc0d1024adb9a2b32a6a34cc5bb03168266e7df97d3712a41cf9f4dc));

        Pairing.G1Point memory vk_x1 = Pairing.G1Point(m1, n1);
        for (uint i = 0; i < iinput.length; i++) {
            vk_x1 = Pairing.addition(vk_x1, Pairing.scalar_mul(data[i], uint(iinput[i])));
        }
        return (vk_x1.X,vk_x1.Y);
    }
}

// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.6.1;
library GetVK400 {
    using Pairing for *;
    function getvk(uint m1, uint n1, uint32[] memory iinput) public view returns (uint x1, uint  y1) {
        Pairing.G1Point[] memory data = new Pairing.G1Point[](200);
        data[0] = Pairing.G1Point(uint256(0x02e70a67ce134c4e209a583d8b9d1e7510c0bfe126e621d0574dfb2176d83cf8), uint256(0x0b24bab7088ffacd0cb74fd19111713a5fb9b7aa4585b52aad75d59574618a78));
data[1] = Pairing.G1Point(uint256(0x289cc08e7022c9c5561fb49b76a7e8d28d2f5f899207004ba303225fc59fafaf), uint256(0x19977553fb4ffd00659ff851459b339514145b3def7f2cdb0d47fed1f82da8b7));
data[2] = Pairing.G1Point(uint256(0x19bc0e8e716de3f405a9dfab59146bd1c51e4f55ef2e65c243e72a978696da01), uint256(0x14c0dfacd8cabf59684700b98d553a2dedaab7c624e615650f25ab1a8434bb20));
data[3] = Pairing.G1Point(uint256(0x22888fe57e92cc1fc40ab89ef079b1170914ed3e27cd95212905cc89032a89c9), uint256(0x0ce389eb99f071865b9968e9e9814bc472a6b25b6c000677f10dde52a67650c6));
data[4] = Pairing.G1Point(uint256(0x188cb1cf6fcc4789536bcd73b02b211fa461804c418ca5afc86b3ee42a110fc7), uint256(0x0be3de5341ccf4a3b71990eab1e4e8c06aefd66913a72605addd3e78c36a9b71));
data[5] = Pairing.G1Point(uint256(0x26048bba01e5fdeff390a92a1c2e0f2e76eb9cba169419fcf3c5c6e1268c5ae7), uint256(0x19c643b34e9c0fa94c7c99bbf772339b997e93810c03688c6dc66d667379af28));
data[6] = Pairing.G1Point(uint256(0x081498828abd6b77a6efe2f329f709de6d8f52d5e2b2303671c923c933047693), uint256(0x214ea826ad127082227bd9e6b98e5c06be3bb67231dde1641dc1a1ef9dc7e195));
data[7] = Pairing.G1Point(uint256(0x1a4745008370d5ddceda46c8e49cda84cdbab4f467854b649da05675c991bd41), uint256(0x1bdff1dcc957dd4cc5dacf100009900a57e693c7e61c186d0014c3ec794203c5));
data[8] = Pairing.G1Point(uint256(0x280dffb814608f7edb1ab28ab7b5d7e438c8aa40b3802a70f1f02910f91b311b), uint256(0x09c3aeba6c853d3b1d42c869b5c7a69143cbc4c42cb8fbb261c44f14754e37b7));
data[9] = Pairing.G1Point(uint256(0x295864667859d11b966a09f3e4f76ff274f3aa32d1a38b4b58fb6dc794acd43f), uint256(0x2ccddc30fce0d70b63d41abacda918b1b6bce4b2b1f48439710ca4bb7e794fb7));
data[10] = Pairing.G1Point(uint256(0x18cb3b9ce6d20649c58b9727d53186e7a936fcc0237c05624bbf0075f9aef2ea), uint256(0x1b4978e94dc31aba60747359ff819c3211d831db06756bda25c0de2c58dc86e0));
data[11] = Pairing.G1Point(uint256(0x194dccc958d41dc3203ded4b1947dad4bd4d4476534fa42528a8a1cd2ae12df0), uint256(0x11e3c385c73219712504dc63f97c4cb7dc50b3246e0661179f96c8fbcec01e66));
data[12] = Pairing.G1Point(uint256(0x071e0e21a6dbe7b740d9f6cfcda1d02e69f12327372d1e3d0771771f1615e527), uint256(0x11c9f7618cd32735640873b3149112e07023ee5adf6ef7e385c568917b2f9f7c));
data[13] = Pairing.G1Point(uint256(0x14846ef553783bc2a8867097ae288acd0ac0afda77376b5a72b6f516443dad41), uint256(0x2360acc01757627d15a150bc35171db799ca262ad1c0fb07286221ab007ab5e0));
data[14] = Pairing.G1Point(uint256(0x28e34463ab26b7ee160b3297588eefc71fbb44390e3072c3c77819b5ff6e79d4), uint256(0x230d5da60c1513b56e7d45cf4dfe6ec2cdf13ec8fd0df54eab35b960e91d86a9));
data[15] = Pairing.G1Point(uint256(0x16aabcea81abe16ac0b17c2853172986dc9b7663bf83127856ede9fa96db7bcf), uint256(0x0a0768160117eef82b72be41d1ca8b9c424b6cb0cdfdf40aec7403d4da8c53f1));
data[16] = Pairing.G1Point(uint256(0x2d4e4e63bcc016dc0b7bc233854554130c88332b1b1deaf982bb0ed4dbdcaf21), uint256(0x221ad839d4842ca1262ac9db85c0cf9f2f7a0ad8494a7722d47384a09fef4d16));
data[17] = Pairing.G1Point(uint256(0x2f76d911814fce83751b50136a81d9a546c6c8f2f479736c8680000f2a5c11ef), uint256(0x00473fee5870827ac81ac39357efd92d22659c8460ca404c37e82d50a90c4845));
data[18] = Pairing.G1Point(uint256(0x0df16c12ffc4cc9325f69d60dbbf233cbbad61fd0ef57775f165985cb68079fe), uint256(0x0437e45362d566eaad3ef0bd3cdd72d1e0ebbc56047421a5aa6f7e985c741f0c));
data[19] = Pairing.G1Point(uint256(0x21d37033f3615d4e2199ee21676cce31501c27467ede5e6a5b16fb21e4741787), uint256(0x2162d1eace131ac3b6668fdc7f86b7edea930e596a5bb5aa2f36fd0aea38d79d));
data[20] = Pairing.G1Point(uint256(0x06250a8327b3cae988495a2064d97fb34c9f05828e01457ebcfb6188bb40746e), uint256(0x2587ced14998f3c53d78fd1011397d51baa7ea544c2be66cbfc5e42f275be5c3));
data[21] = Pairing.G1Point(uint256(0x2c3e83dabb58d556941d01b4904fc4a692dbc954b77a95c9f3647b35897f8aa7), uint256(0x08b39effed15b2b06c493cc713408aa6907169f435c76b1f002c1904e313ecb2));
data[22] = Pairing.G1Point(uint256(0x18b8526cb6088ae63a0e4838e0815fcdb0f49fd409ad127877e601798cd7b82d), uint256(0x0e80731f8ee33a07cb258354f2df80caf340292007c5c85f99c05618a1b15c25));
data[23] = Pairing.G1Point(uint256(0x2cedff9af478db6a5b60a97b9a89b03a4017c1c7d54c1fa8072d4bfe3cf7af14), uint256(0x14c44bdab4626fd156c04b58b8c1a1cc189829e19600fd26f88dcc559c162af1));
data[24] = Pairing.G1Point(uint256(0x04d37e156b6bb23d919443fb38519734af9da9f4aae0f44e2a37589da55787d1), uint256(0x1973b47136a484a5658390e4a8e82238fad2996ac5e80ddc7b452a157cd88d23));
data[25] = Pairing.G1Point(uint256(0x2113edd3e677e382d4f52a90c526f1634ff8876d5c71acc2285c21a2b33ef7c8), uint256(0x2726ffc17f2b2600e201f5cf5a39be038e066115d7bec0b70bca9e82aaf654b9));
data[26] = Pairing.G1Point(uint256(0x29325ba8970766fa14cbf05f0eba0a1afff92faeddafe68cbd18c468612d1a22), uint256(0x0ab9524c031701bd12ec70e62eb6af6ee1fc7719f4dcd9b188a752b031eb094e));
data[27] = Pairing.G1Point(uint256(0x13dfde54b3505a9069bcf4d8134c95664c092ef573354a873f4fc068f8146346), uint256(0x1599505e3ec2952b83151a9e65e771c72c152ddd404cbecb5c2aad04bca4430c));
data[28] = Pairing.G1Point(uint256(0x0994811308397920888bc94c725575ece7fde4de69841e4e193d988c6cdabef7), uint256(0x2a954b5665202356b927d5ffb15a76ccff92cc8f1dfb677e245f8ec81172af58));
data[29] = Pairing.G1Point(uint256(0x16e9b1664068646a8db58818db0fab5e608bce2a6e12860811979a584d144b96), uint256(0x17d12eeb1fb9afe538badb4350f48b6aab00262da5eeca992f0c00c8ef7277ac));
data[30] = Pairing.G1Point(uint256(0x09c754b185716017239ecfd924a97e603063114eaeecf47d986e9463667334e9), uint256(0x2edd7129e40710df65cc7f33fc4727398d3de9cc12c0a34d35735dfa212c8ec6));
data[31] = Pairing.G1Point(uint256(0x06f4bd19c94d4846322e6f10a770719abea4dd5c00c25e2b3ae29c0bc5111b5a), uint256(0x105379700d51e18eebb12d8ee4ce31d8df8b11ce818058b546613d97593fefb6));
data[32] = Pairing.G1Point(uint256(0x2b623b2606fcbf51906c65044dd2a6da44a1cb6cef7533124e7a9c034d4e8f10), uint256(0x17da09e4f271900ae436b8cc41086eacd3c5c67b3012af257b12328589e2bd99));
data[33] = Pairing.G1Point(uint256(0x266b6756ef13cf8cbd771017ae2a732175c37785c8811e4787d39264bbda8892), uint256(0x21fe72d04ef2ed22e248b474abc995edd101d286e907680f03a82f1961fb2528));
data[34] = Pairing.G1Point(uint256(0x209f9c8da1f1fe87094f873cc895a0c7b6c7afebfe4bbeb29255bc1e0b01767b), uint256(0x0fbdee20caaae2a917f64b2d1deb14e5c90a0d2b70a944bef827941f5a7bf818));
data[35] = Pairing.G1Point(uint256(0x2929e70c960abfba239812c76740836a6c232da5f9a2361e8cdc6476d15ae3cb), uint256(0x16a22f8c29d04b0336aeefa5fa174d96ddf26fb88ffe02a71830d2600f03ce8f));
data[36] = Pairing.G1Point(uint256(0x2053134d50856b3d41b54b677f683d8e6cc81fa7e1a03f1651593abbf879a2f9), uint256(0x08b074502059beb73784b94a9c97a0a6dd26679281452d37ecf61ea8c795fe41));
data[37] = Pairing.G1Point(uint256(0x00f1c277adf28d6ba457bf9492101453e0feaf31ae33c4fc57b2636230bf5096), uint256(0x0a96af33681103fa1deb7189e61e34f4bc463b63dc6313da2c9ea76e8349aaba));
data[38] = Pairing.G1Point(uint256(0x2d2a7ee4666cbef987d104d8e6f7b00fe0b4214819bf906a504e676100544058), uint256(0x2fa43fc91ae7753203e54eec8a2febdd2d7229701bf35b00bd25589a183b0185));
data[39] = Pairing.G1Point(uint256(0x24a5a8be949517638532e2f20f9128ae05b1cbacc4f0b4cf6bb3ae7cc48faea6), uint256(0x1a80482790c8a95b632803a57b545b2ac5e796ed8a3610108975c337b9c7b30d));
data[40] = Pairing.G1Point(uint256(0x006b8c2de074d5e3f67292bfdacd487d5c4dd11c040154590de32741eb29446d), uint256(0x040172eb1de5b55f97ba8f3a3fc7d0b39f6f07cce1325677d878a23cc84f364b));
data[41] = Pairing.G1Point(uint256(0x07ca468796593605ab14635e527d40e409a5725ed6c0a650e3cee4d7f2fd4053), uint256(0x1e16ef397c9b8e72d25daf4bc2a7ddc5e462ea09c22a17be1b9de1dbdf7e55df));
data[42] = Pairing.G1Point(uint256(0x2a5c80022fd64bb15d8189ee95cb1fed8e29ab7eede90a503c52260a2204d220), uint256(0x1d2f800ceca6975002210ee8a4437b017ec047b9dbc2743136ef9ab4c7d3fa05));
data[43] = Pairing.G1Point(uint256(0x0d02b7f7cb94810b5781224443ee295d76f1c25d0a388ac872c01ae953f6a85a), uint256(0x00cf6bbb9306c66a64dcf8ea9b5b0eafbcc1522f5a06a516a28370939d7849bd));
data[44] = Pairing.G1Point(uint256(0x1b548f30b57519eb6294bd02b4ce54d6d53cf34042e77c9ad61c765415990fe7), uint256(0x0ba3186844e781edaf3d0b88a9f7a0a91f3ef67d0fad8c1e9bbd9b1027864544));
data[45] = Pairing.G1Point(uint256(0x303600acc6320037e75c9a54945b6cea485021b932e07e158a740cc0882efbb2), uint256(0x2ae6a1975c89ccee07a0a8efa687b65f3cfdb7154791eeb1ed3532b9863c8f26));
data[46] = Pairing.G1Point(uint256(0x25d9fc7defdd16e56ddf7ea829ccf97e8b5ce81651dc5a2f8a1caa27d966cb95), uint256(0x2a8fb66586e88f61b602296e07803f4eb977bc947987b394e8a53bbc359ceef7));
data[47] = Pairing.G1Point(uint256(0x048aecdd2f74f5b2e2650e03c4d1575d6fe98ac1b2dba65fcd681ff6f88cec67), uint256(0x037d9347a8f75d01ca1d0e435749b1d3c0017fa6fa9487ea71d9da531337ed09));
data[48] = Pairing.G1Point(uint256(0x22c12184298827583566b2ccf242770935a57f558bf30c79facc2749a00f0ec1), uint256(0x148af669abbe6d49c08ffad4638486d0bdff32e82926969817f49ae87279ef9b));
data[49] = Pairing.G1Point(uint256(0x2362a049646ea2358b7323fb449a4e7677f507691f70ef33e5314ef7e5d7276c), uint256(0x02f4609e156d0b39a4d0d075aacb77c1787c08574aa75ce20a5622e094b3d3dc));
data[50] = Pairing.G1Point(uint256(0x10ca952a961b5d25f6cad34c4c5c0cd2f1f048b4232c3a8e4b0a9e722a3448a7), uint256(0x24874028cf8dba20f651ab13e23df68f3817fcc97231855efa73102aa27f0f71));
data[51] = Pairing.G1Point(uint256(0x0a5f388dc916649be602408977eeeff307de063ec5c2295cce3e05ba16b93c05), uint256(0x1381beda2804a04bb6acce7cfe299a5cd2ee39862a22ee8af3db9a20b8d8fe97));
data[52] = Pairing.G1Point(uint256(0x1ebb944e5acec9106a624849aabbdf1f56d072656033000577dce19b8df5651f), uint256(0x1db08d5cbeb2758ac4deaa40256990d99362198cea1e098471d3520924bfed96));
data[53] = Pairing.G1Point(uint256(0x036bc69c053a101fe679645d68152a1b01558f32f1618910df5822b1f066ccda), uint256(0x04311fb3ef886e7196c9cc30dd28d9a0b49a7b92cced60540ce13edb5dcc822c));
data[54] = Pairing.G1Point(uint256(0x0005a45a2a6ad6a5a38d56a335aa8f6926141303fe41ec93596bd7d51a5c201b), uint256(0x16d32acbaad1a742095f17b0da838b718490882c7acece38c5591bb71f3fbdd8));
data[55] = Pairing.G1Point(uint256(0x06f1b410b269e9f61d2803e5680dea81ec6b5d4c9e820edffe48086fc347456e), uint256(0x170ca8b2e35318d7b436c30c29e471274b367ac33433522a58e2374e6bd13c65));
data[56] = Pairing.G1Point(uint256(0x05f31df70a78e02ee417dcc9536ca3462937341de32cc556c0c67fcde9feddb5), uint256(0x1456b53e8cb5fb7eec05baecd6e21844605d07fe034f21708cae5227b2c251c5));
data[57] = Pairing.G1Point(uint256(0x221baf7382456033f85be4639ee47b55f46b57551f89d4236ad8f7960df4e797), uint256(0x223b028a68e17ffd15b6957642e80f6ae34bdfbe8c950f357cb19e83c5691dda));
data[58] = Pairing.G1Point(uint256(0x1c7d7a6a4bc145615ac6b3ccc7f7c3b79429ac65a8a50dc0df8e243f2b78d147), uint256(0x2937a257db63649331f04140bbbb6e3ccfa02a27c71bbb8e35549e2313d38394));
data[59] = Pairing.G1Point(uint256(0x149a1875edd4b97d2dda3f318e76b1c85a273da4127b7be1cd2ad01f8cc2952d), uint256(0x2425389894e1d17c273c694d69959b6f4648f7beaa5f46914a6c0f42cddc04d3));
data[60] = Pairing.G1Point(uint256(0x1095a388a24f2206bf0a4ee14c82cf60f2f4377e122c6abc6d03494ad2caa485), uint256(0x17285fffe30b0ee020b31f2e59e4f333cc9a8280bea9e900fcf24e6b0eb0bca6));
data[61] = Pairing.G1Point(uint256(0x0ed203c236e93430b3f9001f1ebe47f3c78e54405d4c2fcf3bc01081b86e5b65), uint256(0x16c98c191252ed5c0e926004fb2757e4c86443cdfc1be308610f667a0d3b97df));
data[62] = Pairing.G1Point(uint256(0x0b1840b4ae4754a3076a10b2c70e030bc91a6bc4955de94a6de0438b0295da49), uint256(0x256768b323ce163d19de56071338e0b49b911e6ac552e0ffd04adbe30be6e61b));
data[63] = Pairing.G1Point(uint256(0x24d1326f1994401b652293649c04d44191b081998fbf36977763737b0d3b7aee), uint256(0x11477979f68d42b5ae1d009b0ef175d812faab4f09187753f921d13f018b2976));
data[64] = Pairing.G1Point(uint256(0x06232005cdd477c38c016894cd92455eecb280e546b585a64cdfdfe987cd29b4), uint256(0x19ca54baa409fd84ff92ea5dd6bd5eaec8393f259ba3ce0b6afbb7302857c134));
data[65] = Pairing.G1Point(uint256(0x119001f5be9026e7a811ac454046d951b3a7f7864909412bc9c60ae24f284f30), uint256(0x274871bda78a04e02ee8612c1a5dc0d51b6b80674340eb1f7554f4af50c5cfdc));
data[66] = Pairing.G1Point(uint256(0x1a68b59050cbcb2162f97aeb8366e3e50366b44864e0d29402284df2c01f86c8), uint256(0x154ff27c62eee6502eaf31951356c905d316deaac8e121db37b68d87bbf195e3));
data[67] = Pairing.G1Point(uint256(0x0c799bb3ddb90c9b094900d5da7ea8944ee95287d8f48b77426db318356596b6), uint256(0x19050323306376eb3c1a2875f282d5a6730de76bfc22241f5ed788c2e5d0117b));
data[68] = Pairing.G1Point(uint256(0x16851616578d08079d9c6258bef2aed8542186995cddf5412814df6221bc165d), uint256(0x2558c4aebca1d8bac71de9c2cbadd0406a8608cfbd0a125938fb0f4f47909f90));
data[69] = Pairing.G1Point(uint256(0x08c955a25c5d645cf4ed10e87de06f974121c058e931d757801b4050102b3d9d), uint256(0x1e0367c7f5e8f157d88d5ea90dca129678e7d5201b19e076c1ef385d710cdf6f));
data[70] = Pairing.G1Point(uint256(0x1d85eedb8a07d51874614b54c8567c95d0887117212deeb269f2da91ebd96b8a), uint256(0x201fa5aadf4a510f67548ac4eda1d4b4fd2724b883406efba52a6fc5c32816e7));
data[71] = Pairing.G1Point(uint256(0x059e136a4c05508113a74a91fa6e333a3b449dcc27c01814fe828e8aef4559fd), uint256(0x12e9daf059dd73c90f52d5b39ad7448f7ba7794da756e420b643f411a017a0b8));
data[72] = Pairing.G1Point(uint256(0x001b41aa99473a02ee90e9ca0e81e4afe4d19fae1846c8c49faac9f0b8bac5b2), uint256(0x016c50c9b61b91451c1087d0acf52b3b34bfccb6f9bc2063a4f6fae72983355c));
data[73] = Pairing.G1Point(uint256(0x2764789aa7e247803f69d91953272cf926cf26253e92f2f9d709fa320c9fa53d), uint256(0x179e7ed56b06676d16b29da34cf41043082fd3be4b2999021ad8a01fc8ce0ca5));
data[74] = Pairing.G1Point(uint256(0x0d062b5594c0b34b70bc56cf74d76c29afbc2859ed6ddf5c6b4dcc6e96961727), uint256(0x03326dcc347ea99798765fb8f5cc3e7ca2aad83401e3192acaaaff679763e5fb));
data[75] = Pairing.G1Point(uint256(0x2bc944ed01a7643f40943625de71e4441d1ecd4576f399b28f49ba109b4d6e54), uint256(0x20afd7aa8d61b72a3bd2cd9555a1b32ca655949a5e48db636f4f0600f48c1884));
data[76] = Pairing.G1Point(uint256(0x2084593ae704f84a87d0d28df1318149fe355cdf65862746a75c8ad25074c09c), uint256(0x04a7393410811939ca8043162b1e1ef8c1f044d60a4faabdc40dc5c5465c0398));
data[77] = Pairing.G1Point(uint256(0x0609172b61c528cb6c0787df13fd00d153bd437cb946ee876498aacdfc0f0977), uint256(0x0fc46d0996f220169b145823dc8571c5089988eab00b23e2751c0b4bd73b2766));
data[78] = Pairing.G1Point(uint256(0x2b8f1ce77e38d363b7c5e836bfedb7da00179b87eae3e4b12e02f7aacc3f897b), uint256(0x24d5c5088268f5df99a6e69f40e6314d594948d6b5a1c0e454761dfba0492c7b));
data[79] = Pairing.G1Point(uint256(0x24502cef86452deee5f2204b4f75539bfe3b891c09ce5ab84e59aa474f1184ec), uint256(0x0ca98c6c77e2fb621c7715957f7b6c59ee9c0faffe861ebf7d4a850bd38a50b8));
data[80] = Pairing.G1Point(uint256(0x0021ff3ba0002c4f587495178aa16207cdf202db67eef3b7b5a1fe1ba73e0579), uint256(0x1d6ba8c7f2a1a67da74ba0e307327c7603b83e9b0462ac14b17cab3e9e98d05e));
data[81] = Pairing.G1Point(uint256(0x01371481b002ea620b76173a97dceec46c93d3e2801c8d1efca04371e5c9c87d), uint256(0x2e181183127c77627c5d75aed10ad6e3475c5ab02eeaaf003e4917de6a6bc11a));
data[82] = Pairing.G1Point(uint256(0x02b6ca22adb29d820c407392a4d1490436736c57c3a9c24f0b51b5a98e3f091a), uint256(0x151b9314df7d9c52bf49aa72842b0eed137d9e362f14e04bd1ced3653c3b60d1));
data[83] = Pairing.G1Point(uint256(0x2076981d706b7d0a34c70a08ea000027b5115430611376cddc465bc8d3351ee3), uint256(0x2fb45b0f23eb5c117724db8c3f3d5b1d5b4f2ccda63e423b73e51291b4a19c70));
data[84] = Pairing.G1Point(uint256(0x0378dd499da3f649f450cd4224538222e7d4206e74bd899be63d0a3a4b9c0daf), uint256(0x2988c63b64edfa7f5770cc43d3881a6375b46d139e405ee8c1d3f007028f030d));
data[85] = Pairing.G1Point(uint256(0x0ff69c7f9072e0608b8de2a9e3caae623b29bc1ee67efb2403d2cc995a310b97), uint256(0x1cfbb033e1014075ab63bfbb6abad87d337c02eece72a45a14be61886bbf170c));
data[86] = Pairing.G1Point(uint256(0x16086e0d5d26eed8d15ae1fa6069b82453255c3f3a879eebb811a7f96d0b966f), uint256(0x04a7c257aecbf163a9c4a0f1792e6a073459d6a2c3e636f96cd689001240a7da));
data[87] = Pairing.G1Point(uint256(0x159d107045efa91345f067df81214df2f2860bc01ca95f4c48da0241afd32b24), uint256(0x135e9d826e06e5748e8aab652537cf45f386d0327ad17d2e3b598a111f0990d1));
data[88] = Pairing.G1Point(uint256(0x2ed4ed190c0127bb34fb8a1b059e12fde323c3248f0fc7628ac806694b617a2f), uint256(0x1f716ecfd47a5acc5cb1efa04ae72bce2f1d82cc3d107f160d26c10a697c540c));
data[89] = Pairing.G1Point(uint256(0x099d895cca4b1748b1ee2e33ffe9810c32cf7a3f103e16b9a70906868b4263b7), uint256(0x2e143178fb09950c689b9c57a289a7e0ca02c3caa1d0008347794dfaa08b5625));
data[90] = Pairing.G1Point(uint256(0x00119ca89349a5a22349a39c22fc1b26f306cbc35a345a6c70e7b9f6f920dff2), uint256(0x0bc230793e524e80483a463091b0e4636f75a489f40cae4ef8daf3de711a7095));
data[91] = Pairing.G1Point(uint256(0x1471b1bd795d8796c755a6e4b3bb8ca2991c4f7c4a2f179fa79f32f631ef50d3), uint256(0x0aca7079972ef664f6c6f8cd22cd6210711b2cfebb7e9775f78324f562bdfffd));
data[92] = Pairing.G1Point(uint256(0x0017deb177956adf25c63d4a96f25665aab654b2ae0cde5cf534e208d1525897), uint256(0x28c35b35665ffa285bb3c3bf9e500b57ede46273d49946b5edbbc177fd709528));
data[93] = Pairing.G1Point(uint256(0x2e288eaac0a72f81feeac2c499f893a2185154ea390febf74f00d81f83fcebd7), uint256(0x14902d937a143f77c39390947b5f87d9965793130675f1f78425e93397fa8808));
data[94] = Pairing.G1Point(uint256(0x28e8ec95a6969772022142da95b499eadcf2701da43e1023dcb48d3afb063c6b), uint256(0x0c413d34c49595301a08e461cf447bcb155f313daffb9a2fedcc85ced0fba30a));
data[95] = Pairing.G1Point(uint256(0x27bcc548cc32d8df5e7966ea3b9ee8969216bc1a020b8dc81c7b25682cfef995), uint256(0x1e58b23d503b0c936caed9696edab6b0a7e942a6261b812322e1e1aa387e41c3));
data[96] = Pairing.G1Point(uint256(0x1db821659cc5b79d9ef3bda4292666533907f0073f418c62b5e21634d66d3ec9), uint256(0x06209d43ec01772ecb13196cf0b45ffc854b5b55eb576013782ae989e796786f));
data[97] = Pairing.G1Point(uint256(0x1382d2673b18341b63950e8145be3a23ff057890154b007d30c63758da6bb701), uint256(0x083198f0670abafd1f50b8092321507bb311ff7485c0ac42104422edce1908a2));
data[98] = Pairing.G1Point(uint256(0x2b165f79e7f02ed049b06f41f8bff23d6a7cc225e1841b3710b27c4538e4ec64), uint256(0x26251892b06d298de11e1c393a005b50e9a6def6c422fe7d8097142ae600eff4));
data[99] = Pairing.G1Point(uint256(0x03e276b086b60cb98d1ac948e4f4242dafe426a3621b9ab2228120be147d1da7), uint256(0x23131cbb745deceb8181aa29636486f74d05ab41dc0ccc2867ae9a7cd1c2aede));
data[100] = Pairing.G1Point(uint256(0x00d7ed7555094686de37b4b56cfdce43631727aee552f2fd365c93ee610abcd5), uint256(0x22f5d5f9ee8bc627bc598ed4a0d9a7442cfe38bd3a27375542d9c7649ae7a630));
data[101] = Pairing.G1Point(uint256(0x1929604df2c276ccf85948a3e20cb14690d73bf8cad88f308f51671c955cdde7), uint256(0x2c0f5328f3f0aafe16c69a5a9edc4e3c1c55f74077e73771f960b032d0cb7c77));
data[102] = Pairing.G1Point(uint256(0x2818bc30f0a5c18ea369b8f2425376145d5a373c2aa8b803db3ea78834aa904c), uint256(0x0b1fdf67eb20aed3002bcb741c8f9feab2e7300a08367c8652b6658e4f83c4bb));
data[103] = Pairing.G1Point(uint256(0x2bc4bcab7d916d7de814eda6299167b2be09ae37c03840e666bfa076754be302), uint256(0x0f204ecfca0a743c3989e21a8509844fbe33fbb5316e60b2060788f7da2a76fa));
data[104] = Pairing.G1Point(uint256(0x26a312ee7a3e171a8d004dcae1a92beb6a1de8bcce23ffe7b0ae419b415da22d), uint256(0x239a2396f0e375e989a794b7376f854c2ed17dfde974f4f1d1ece9976d57f49c));
data[105] = Pairing.G1Point(uint256(0x19019084394ae2613be10ca949ffc41200037930752afda13eef03064d03306b), uint256(0x16d74bb510976e7eaa3a49d376ccfd72caa9c4d661ead7fe516edb5ef2e75d0c));
data[106] = Pairing.G1Point(uint256(0x2730d051a05f9c014a59355b3bf990721466e0756b7aeff74a1330dc6e69bc5b), uint256(0x1af1e6b3cf6e92ad37c0ba78bcc718672c05b4557572ba51c9d9091d1977c8d6));
data[107] = Pairing.G1Point(uint256(0x212521021d7acb8d0e22bb60e442d8cfdc00f4cababbce18d4cf8c10d37f86ee), uint256(0x2a81282d11d791926d1bd3bcff1105d5107c5e5a9aaf3e7b30b3548100118550));
data[108] = Pairing.G1Point(uint256(0x00130ce25059e7190aa4ca7aeeb0577721b1f80360f16a42f57db4b11080ce0c), uint256(0x1e359aa98a2007cb0b87f59f7aac0a0ca3338f645fc885479af29f22242cf009));
data[109] = Pairing.G1Point(uint256(0x0491fce3dc80bb78bc3d366f487653e8091e3dc4971942b9c9746c1d7a5747ca), uint256(0x1e445ab4893b0dc56d1e46612ce13208dfab9c33a9d56d45458fb19d7d625279));
data[110] = Pairing.G1Point(uint256(0x2f5d671870797d711bb351e9f2d4331992b5d74165daa4e7445b2321102b64e6), uint256(0x1b519554c73346c21a3622bd44c5e4b07f78cb3dac74802c118cf6d3237cf064));
data[111] = Pairing.G1Point(uint256(0x0aa9cee1c621cc0a7dada77df12e085508e8f22e15bf5566337d2378736c1f45), uint256(0x097658a504c27fafab169e61776c52fc6ecab4b9f11498d18ebefa34ed4f9c37));
data[112] = Pairing.G1Point(uint256(0x2d808afb73e431de4bf8341b66fe1a1f96fffe0037d493eeb58a2c508c3cd0e3), uint256(0x0923b618389c719ca671cf6c38c4107b22424621ef76c8ab9232c3d6832d492c));
data[113] = Pairing.G1Point(uint256(0x25bf10ccc91af1bc2e715ac1e415d000d6a58ce37ed6cefe749cbb1d0467810b), uint256(0x2473f98cc123aed7f90ee76f9e535e2a2990e011d41f0750abae0bda1e89269d));
data[114] = Pairing.G1Point(uint256(0x0a8d7307a67649ff886333716184b2ce71600a6ca336cac5c86ec6df5854a7f0), uint256(0x28509535860c46af896d8e2c1900a241fae5bb510f01c819aadb11a3b788aa34));
data[115] = Pairing.G1Point(uint256(0x26395ffb4b3b5f480ff2bd7c30706218bf0ff04ec484d39d526cf7f4030b6c32), uint256(0x2f2391459f116d821bcfe88d54e7ba70c53a1a14b88e6ef2e16b7bef1771464f));
data[116] = Pairing.G1Point(uint256(0x2c1e82df1ce708a9608192cffdb9e5fa7ce5f73d7068a457ed777c132e26c7ca), uint256(0x28e967ab80cac07dd012709552a81f17849699da807effc666efad168760084d));
data[117] = Pairing.G1Point(uint256(0x098fe5c2149f6e5d4969c752467a2e5b739b24a78d6813fa3be292c958e75c57), uint256(0x0b26c8f3530cba00ae7ec023538dea1764b1693bb1efb4e48a24af0cf4c0c870));
data[118] = Pairing.G1Point(uint256(0x0b477f375a359807f1823219da604a63937f68e6c5ff2a228165313f81b9ec0e), uint256(0x0639c92c80ff0de00d0ae0be3269e3c000256bdabe53838b6655d852017d7bdb));
data[119] = Pairing.G1Point(uint256(0x04c6efa4224298ddcd74c679c15ef398aa980662ce7d97929e3d09443ec0cc1b), uint256(0x052d41d5ea0413484c7eaae3a3114f9bcc4d392385fe135bc77b0164b94e17ff));
data[120] = Pairing.G1Point(uint256(0x260af77cccd58cf390ad71e009bfe0aa442f362f6f600974694ebf1b505f944a), uint256(0x27e0267270412f45223ccef11b4571b57c0dd18b39112675611054b528594cbd));
data[121] = Pairing.G1Point(uint256(0x18082b8489d9579fc74b0fb8a05d56f1bb0521b197e1315b70e253ba5c03d5cd), uint256(0x0de373878c50d215c09ec126f271edac14a0a4e743b5e37497120eae4277b255));
data[122] = Pairing.G1Point(uint256(0x13a5d8e36efb659b84801151be443b2bcdb99c206495e0ffc60992114e9542bc), uint256(0x2b55ffec6150d31354e50c97784f3bc8683ca5581362893ca8d2dbbd35b523ad));
data[123] = Pairing.G1Point(uint256(0x21a3b28c2eaa68d2cead0966cd042c6a6ab1e60a10764b5958a74cf51d31450d), uint256(0x2a64de1e4f0d0496b3cbcc8c95b77ebbd33c89065cca631e1f54983466197753));
data[124] = Pairing.G1Point(uint256(0x2be010e1c62738defa370a4ff1c0cf3ce9c128bd99036a772f237798cebc3445), uint256(0x08ba5cda1c3de8b305cee53bb68d100d8c7513d923e20b867d208eaa1dcc47d4));
data[125] = Pairing.G1Point(uint256(0x11f64866292c3231bc9797b7090650d809cc177a8e76d1d8d775661c1db3e4ee), uint256(0x0e829f4a7d399d4ed25406192dec1a2a87c8a59a0ff05371c82d1b4f178532f1));
data[126] = Pairing.G1Point(uint256(0x1e3e643abdd10085f3420e605dc5fe240fe72a9c9e051ad5f62a604129cf4f1b), uint256(0x2c92a478fad39494215af1e92f6ed25b229ae90cce1cdfac565fbe403604f383));
data[127] = Pairing.G1Point(uint256(0x14b427d7733d1389b602440ad49c9a0a3f2398b287ba76eb4e4d0ef22d6ff59e), uint256(0x103ae2b30a5b83b7aac8dfe668ef02848a86a74067a729e2df6feb5228740b94));
data[128] = Pairing.G1Point(uint256(0x161e6b249522a7ba44d48666e9c11c85dbc452b012ec0fd8ae3303e1930ab693), uint256(0x03e2b8d3aaf169ac1a443415fac3cff12d4cedf409fb9ac8d44b8526f1eb2b92));
data[129] = Pairing.G1Point(uint256(0x0b9318c5cba577ad1f3c4b3f0762bec4cf946bc6726179c647803c35a2039874), uint256(0x1b5a9a61b4f91d830dac4d1bab4355a0bcb679b6da117584ec652ec5c46265de));
data[130] = Pairing.G1Point(uint256(0x11f69fcf2a6d0d0fa2e1520d7d50b5bc0cef0521d29aaab1c18902f1dddf3bab), uint256(0x0b0704fd4f2e746444d81e004bfdd16ac1d36b1eb25fe0a109d1653c827c844a));
data[131] = Pairing.G1Point(uint256(0x106694382eb916f3a74a843f38e97fe73fc614372a15826497888921f666b989), uint256(0x21c55077d385094190ffdce0e030e07b98462edf96b8cd9d3fa43f617d174012));
data[132] = Pairing.G1Point(uint256(0x0f90742dc216b23c4f337c0a53662208417eb239118dafccde7d44ec161ed0a1), uint256(0x1e4441b17d193efc24fafe0b4b45bf1eff0c577c14f35b527aaf92c987e9a1aa));
data[133] = Pairing.G1Point(uint256(0x1bbff410cfbf6291d1d538fb8296602632c94dd4dac315c2395c392a64c8cc01), uint256(0x2f5ce5db76e08408d83dab79b88bac453bb8f7d7b05f5862f24aa46da5d859db));
data[134] = Pairing.G1Point(uint256(0x1200901fc2374dbd549be198166ed83b906e84a7880e3282d3945bd688fdd504), uint256(0x020b7412a31e9ab4378d0e3ba64b0dd0e428a0f631ef570268313ecfc6358646));
data[135] = Pairing.G1Point(uint256(0x2cc1a0d51c3bb44aac4c60356c577808dc51d7e718bda197d870bb3894418def), uint256(0x1e6e1dede1bb76c3dc5e57eb05682e36d9b93ce0feb35f7f76bc64b30547e06b));
data[136] = Pairing.G1Point(uint256(0x104d2e3c1862db2efda79df2beaff558c01adf9b5e24ac413d39b9439ef18ed0), uint256(0x29f8f160bfd542d1099b481475c5e0ee4da8c457d1164934db5c4faa2767f55a));
data[137] = Pairing.G1Point(uint256(0x2feccacd96a66805df9f282b7aaf176e8179a69dbb8fa6c2acecdf85857d6b46), uint256(0x02e8b7e2146e05192279602ce7fc5948bc14986684fa31060e293424f05b9648));
data[138] = Pairing.G1Point(uint256(0x02e8e8685bebe9321c50833e00761ac1c00ea11b2200dd3707980a826dd3a1b7), uint256(0x22f3416bf5ce49fcadc0bc8b54d92b8e821075a3964871b642232704d9d7ce09));
data[139] = Pairing.G1Point(uint256(0x1a5a9bb63532685f582553f16393d0a5100853422bd0a1881781206f0a53a24f), uint256(0x2a2a11d89f494b7c8655285fb7bcf0327265911f3f8395896b22f3a34a6170ee));
data[140] = Pairing.G1Point(uint256(0x174e84b1cb7b6302fcb762cd5597f115b2092f6fbe0e79bb7e374ee9edfd246a), uint256(0x0303d06dac4f26f3c91f8c781a583eb7f3aa57b0dd23eff92d1931d2937f2934));
data[141] = Pairing.G1Point(uint256(0x2251cab2390e9a96e7b55d3d9546cc263a94b0c355da02682dad6572ef1db2b2), uint256(0x2f344c04408d0f39e2dad653a09fcc95c61a6ac1261b7be78069288c110e0d56));
data[142] = Pairing.G1Point(uint256(0x178b74076f6b53678e455ab0ad07fce85653a64c9c2ab005a92c2c45d5988037), uint256(0x2e836d09736eb6d228a016f6c955e7129ee88c04a2743085d2ebf77e71b2d605));
data[143] = Pairing.G1Point(uint256(0x08b5efd96759db30db56437d1642ab1f2564472633a511901e79999f901e745f), uint256(0x20279505e822c8266a34ebd45ddefe8d53503fbd5c492384c5d10c5ad3612a1c));
data[144] = Pairing.G1Point(uint256(0x1aee8af76be8ce62e4b9063c642caf816fe98e8b958e98d729584be15b50fa43), uint256(0x0df11b3063c4b351b5f777e2f3444531f1c8f7375b08610d09b1bea45bd6924e));
data[145] = Pairing.G1Point(uint256(0x2c6e0a35f271f41d3958cb02ef307067a656ba55e2e25ed33658864e7c3309bc), uint256(0x010eef0162dd7165f654870565df4ec5cecb31a48361551bba9287045b883bce));
data[146] = Pairing.G1Point(uint256(0x2a55e48202304b652e966928563c8b88b2a5fcac14cf6a58d408317da92991f5), uint256(0x001517ced8a089f50a83d22aef6969ede935f89d1c5527617728aef6f4e47aa9));
data[147] = Pairing.G1Point(uint256(0x293f7d81ffa7688693643629b5fe9fa76cf5c55230950d11dbbc132d2eafb011), uint256(0x295d259c798ddf1e6d2f8a06628b787867830b5d1d4c82f228d06d64d6eb7a51));
data[148] = Pairing.G1Point(uint256(0x2022772fd09c7b7ebe9f8e0a1adc042ba262861f6e61364cbf06ec0dbddaf959), uint256(0x13c9abf1a2e2e9e5419e59a7a86a7ae9caa349d7d7da2eeaecd5c185055bb311));
data[149] = Pairing.G1Point(uint256(0x304117385c4751cea8df1f887452e9d3b7de01af1664a21ae2d375ec33ae6570), uint256(0x0a461401020b6db19ad969de54a9df465ce50f93d1c2ca857e1839f229956a71));
data[150] = Pairing.G1Point(uint256(0x1b16b6f24786eb48584b35e5c28f9458fd7577a2db7dae7e032f3587b58c5de4), uint256(0x29b44ed5975a415f45a0db0a53f870caf92f573ca6edb6de1ab079180e49abbc));
data[151] = Pairing.G1Point(uint256(0x24d4fa60045fcdc95d5cf1890ef9de6946f3e50be7354af8be986ce9c354c0e5), uint256(0x08a008f8939e0ef58ae630054ad7911639111a43bc6629d14e19146718660634));
data[152] = Pairing.G1Point(uint256(0x0ffb31f2b22b656e2bd4a8e85f6ef29fb5eabf9dcd0f089bd7dee70372998eea), uint256(0x197fc1c8f258150465dc145b7dcacbaacb1b37308e8c46285a260185513c57a5));
data[153] = Pairing.G1Point(uint256(0x1641c19c95ad71c3933601441326b68949063b053a68dce19f54969975246472), uint256(0x01026156db228fe59bc8657229dc47c19b8689fde970f698a948f4520a2e9766));
data[154] = Pairing.G1Point(uint256(0x274a00917dcccfb925ed00b66e29e59e38ddf4238a6f1dfb27a24efe00838734), uint256(0x06993a88c8aa706f4b4b28dc17bdd45101e8b23a85439ecfe02e3cbf9bba001b));
data[155] = Pairing.G1Point(uint256(0x013dacc25e00fcd94e6cbc39b471eb335ca9a5ab3cee9a1e0e651b3ebd4449aa), uint256(0x17043684d2fc36faa0fe1a76d264c94116aef6728d6e1c1c5020f8fd85a772e9));
data[156] = Pairing.G1Point(uint256(0x25780a5a28d940f1229b1e63e09c673fb4f0f2a48229d5524ac8d33e5b6cbb49), uint256(0x13090e6f037f63a35141e75eecca72a5b50c0f34001cea2bf0746d8a6e661e89));
data[157] = Pairing.G1Point(uint256(0x0e26f2456099970bd4797f6ca0ee2ee707a7d24f19ec545618ba77f52dec036c), uint256(0x1f287cf1370af4af4d6b1d6bd3a196785d690f050ecd1d29e0138ff42b5509f7));
data[158] = Pairing.G1Point(uint256(0x03c43c815eb20025856794198a5a56275c7a4955fdc3f5f2f86187d831f2969c), uint256(0x114d2939567fb12148d9559db7b81ef53c2adef5eda1ddd815961e7ace0dc4b9));
data[159] = Pairing.G1Point(uint256(0x13d018d96091e63f514767e319733ae9e3be288639c9a6f6ee18be943637d404), uint256(0x2780b967677b43b75f52b37abb1ce778d468fda39cba6340153ed2559601646d));
data[160] = Pairing.G1Point(uint256(0x17ab263daba2ab6f70202ec235d9170ed2f4da965743d220db550492899c69a3), uint256(0x29224d0ceea2b64cba9ddab6bebd4ffb460851dcd03ea6b4c2617bfabba1dafa));
data[161] = Pairing.G1Point(uint256(0x160a2a48ee486695ed029632eead56cc59fa598e3296aa1da40853b66a1deee6), uint256(0x0d80dd904b9f3fa3ea2ecfa93872157000cb6ba8d2a8fba96bd25f2d75645fc9));
data[162] = Pairing.G1Point(uint256(0x00656ea6989914cb2f5be82b6dc95d4e6032300af6f4702f1141b65b1fc9738b), uint256(0x2a69257dde6591e5cdeefad78ae45982a749d8e567583cb670e9f2c06b16258d));
data[163] = Pairing.G1Point(uint256(0x1ae5ddfcdedc8a9b011ea2788ac342fbea9867fc39b368ce8e201cd95d6c0503), uint256(0x16d9125596c9be08f563cdcb4a6cc1ae29959e0f0abfd307e9766d70f5fa59f6));
data[164] = Pairing.G1Point(uint256(0x16ca7f0c1de56f596d93292ffe8cdefd881cbd48a1dcf9eb2fa241b7ad7c0e9a), uint256(0x0c372bf653d63fbe89627b21bb6c1464f00a20352e08b4d5f7c883face42d0d8));
data[165] = Pairing.G1Point(uint256(0x1d7651ca440c02d40939ec057afaefa86e7ee10a1320540d716f229fc2f7975d), uint256(0x2649e20f8d8e351290a919d18ffea6c6d7108a49e0697ee14ed0540612f5eaaa));
data[166] = Pairing.G1Point(uint256(0x000b0bf95c97cb0103a9eeb30ded04d3cbd91d845308e17819874e83d8d083a0), uint256(0x132fc73a2d14a021998eda9868c28e3c5966274babe81a53ae86d7a6e43a00d1));
data[167] = Pairing.G1Point(uint256(0x06e6b65f96e8523470bfa46a6e5669861beea793ccc2dfe988e4f1f639a92db0), uint256(0x1504f82be2f1dfed5c995b739febe3401b2a5b6aa85ec75e2bf07125347d4745));
data[168] = Pairing.G1Point(uint256(0x2ebf467c9e425ff436dfc21f1e8122ccfaf640efd039304082b1f1718008d5ec), uint256(0x0881be300c94390235018d5514fb91039ca1df3d1172fa9b226219c3d4cfefe9));
data[169] = Pairing.G1Point(uint256(0x19a4c81f6a7b8a3caefef069b84ac776f384df7431b597d492a4ebd2b2c0920a), uint256(0x05a8c4ab08d087019aa967beee473d17257130af0bb754dcc47f0fdb407dbb15));
data[170] = Pairing.G1Point(uint256(0x085060291e522f7350243e2590c640743c69d4a84e4fdd13813a3852fdf0fad5), uint256(0x139c21cc803d412088cdb2bd50dd7800241b381975f751f16fb1f8f1cd0a5844));
data[171] = Pairing.G1Point(uint256(0x16d3ad19ddbc446d856782e1a8301824ef074122979a933925f3dea6b5d30dc2), uint256(0x1d28f695058d754a71776f8018e3c51afc749e47792a73e10fc34f26ad2adec3));
data[172] = Pairing.G1Point(uint256(0x27bda9d6354a54aaabd68809a85a0179bc4579e7816c766196f215616d9a7950), uint256(0x024324dcbe0a33e821d10335386353b376ada86aacfd568d8aeaafe3901b4abb));
data[173] = Pairing.G1Point(uint256(0x1f634190706bc0caf702b150afaee765d2de7b2542cca96a7c5a63713f138446), uint256(0x0a412bc06a1175d77da2e6cfff1815d3d7f846c50a0e26d23a5c8e8a00246e39));
data[174] = Pairing.G1Point(uint256(0x0acdf9dfda50da2d9236fa8aad58e4550db4e1afe91906565c0dd633401b59d1), uint256(0x26e5a11fef85e78f9db600e2615c2ef9ec4a86c50384ea0aafdc46f387ab070c));
data[175] = Pairing.G1Point(uint256(0x157568196733803e2c08075da5009ac3d5a511672766111714059d0458defb33), uint256(0x298f4dcb120fa878b35c803e534c75edb4d3dec13d7691981c2c3b9ba85eded3));
data[176] = Pairing.G1Point(uint256(0x2d830dfd96e47f74b09cbdabe571df34c4d14ea6fd8da3474bd79f3fd16800d4), uint256(0x063763964fdf7af9193cfc7a65f1a3e23d2e9d3dacb0ff60dbd30ea27ef7726a));
data[177] = Pairing.G1Point(uint256(0x1ef95ebbef1e3dca54c335fae45ec0f266f8e09142b90851dca4aa870f8a801b), uint256(0x045cb39697626fe6f41797bc0c2220b8d28eb0bdb2260e2b410e3a5e62f5de00));
data[178] = Pairing.G1Point(uint256(0x2086379a24aee575de2394d4487f6dafbf7f51793485a4376cd58fe8276b997a), uint256(0x24ed760c882cb56b4c2069a1a0a33d925479825cbe3708b7d8b51163274ce02e));
data[179] = Pairing.G1Point(uint256(0x267978cc1b9b0e14cd83c725e3540ca4aa4326aa87a45a0f52e8deecbff17b62), uint256(0x191f274916aeba7e530f47ac5dd4725c1c73243d322579631bee573d83a25adc));
data[180] = Pairing.G1Point(uint256(0x067ca0a3098b0e593f1b56f17a0e0ed73a666c875bbec436b8f5c490a638f1d6), uint256(0x2a7c3bf4e83895ced1e3f1fbbdac53ac780dcc56f2e74b855f14db43768b7581));
data[181] = Pairing.G1Point(uint256(0x0310a64ef44afe83c72869acf2e66c10ce2a57b5b2ded3542a117301823aa8e4), uint256(0x2db66769db3f7d7a7c3df93e796c63dddd2529c1a55f94d8a17600910e5a019f));
data[182] = Pairing.G1Point(uint256(0x2cc8f1c6c14ba784282dcf2a73baa71c88cf5b473c4e8aace6b6e6a6338498ed), uint256(0x2c81cce4573e4e76197e1b35dbdad6d36a7f6b5e16a80f3c080502d1414ab30e));
data[183] = Pairing.G1Point(uint256(0x2fc940c9ce71efee146b1efd1d683a24f994ed0d5eea52d3df1103a6972116f4), uint256(0x10f3149fb880e940e18d6f88b7223fa8f0cddd1d504bfd9f74f5bf3eb01b37cf));
data[184] = Pairing.G1Point(uint256(0x2291473c1df1980d0f95a6994a093028ad980d91a1b0d17a4762b1fe67aaa4c8), uint256(0x04115cd0ee1e85bdbdbe88570a9868b631a3fa1b33b9c73c0388f505a4411636));
data[185] = Pairing.G1Point(uint256(0x2cc8d9451bfac43d7b4093f9070c5192538859654cef6bd693d1599c05f1a44a), uint256(0x15b26da3c381b801dca4eca447259fd16560c67707958257704e6af40eda2e6b));
data[186] = Pairing.G1Point(uint256(0x0056cfcff4003a88773549ba5e46f8f313b3185040767aca316bc552b3dbdb49), uint256(0x2528975c5047e8ff1e8b6420931ac5c551be234b0e8671212cca3768e8000986));
data[187] = Pairing.G1Point(uint256(0x08d4245af86e2bd9c63042979e7dff4e082c0fcdb84255daf542fa9bc08088a7), uint256(0x0f771d7b5f8b49f4dad46674be175a28495ebb19302e29b7ab12a992041963d6));
data[188] = Pairing.G1Point(uint256(0x0a7575aae56542fda5e15a5e9b03a454b62a2dbe0e99d9436c013398793e8c31), uint256(0x05ee061dde4121e187cb914f7a73e1f37aa41715cc5eff54f5db17715c920e3a));
data[189] = Pairing.G1Point(uint256(0x1c80147ea28d1e8abd758053726a57580719411e4e643daa72aaaa3daf152980), uint256(0x10f3ff028916c198a7c60fa44769eddf3004da81e73cc24c5db7d3134a62ea27));
data[190] = Pairing.G1Point(uint256(0x2921181d0d72ac093f879b1a15b720786695ff5985b6fe182f40904192840874), uint256(0x057e8b235882fbf0ba82e2344debd1146056ef6c204eb773918ed9e7f3f0f879));
data[191] = Pairing.G1Point(uint256(0x2e4694f92b7ce8bb10d3ae8701302564e147b187f84ec93cc90766eed5304a59), uint256(0x1206398798a8a5c3a334533d06fb418c451388ee0bf2e98aa0bacec0c4e7e5eb));
data[192] = Pairing.G1Point(uint256(0x0a5e4577d484a67cd0efc23785ec3e929c0df5b436419d255478de95b998596f), uint256(0x1f05d5c84bfbc3a2467266e85c09aaf8753655ba7950076a6e4beae7f50a38cb));
data[193] = Pairing.G1Point(uint256(0x2bf6b3f98d272582a893e29c7bc5d95c21113c455ed0beffaecb64c3ccd7d1e4), uint256(0x064e89ed9374908be32c4ef1b297ac4fc41119e14d3c2157e31ae30893c66809));
data[194] = Pairing.G1Point(uint256(0x07ac349fcd222d544c6cc171af847a3ba9866ff2130966c8135fc3aec39ec7b2), uint256(0x16ae6e0d3f850346edcf8293fe3336a4facfefc56c38a95bb5af2ee0f2f5823c));
data[195] = Pairing.G1Point(uint256(0x2537fc66b622af1660b7ac63e1f9108c6d5f491e88a332c990cb6c3836506814), uint256(0x15e3a08a831a665d5d178204430855cccd019c9e356612c50f3a35e16c31eb4e));
data[196] = Pairing.G1Point(uint256(0x224dc7cbd34c71ccf8c2558755359828968182ea0f73b9d255f2312d9a3f6031), uint256(0x236e2a4d244bc642cd280be1c0e85772445eba3730567b0fef60bd92ceef5f7f));
data[197] = Pairing.G1Point(uint256(0x08062eac17e20bb4ce67e98ee99a735b2597a831ca49b1c2a51b8645792404cc), uint256(0x1ff6d9b61a93c7f55f9049785530200c7f92571ff88a570fc272b1f590361b50));
data[198] = Pairing.G1Point(uint256(0x29637ab7a98257f48eea638667a226b1e2bdc6dc489f55cfbaccd60a9d208227), uint256(0x29c9b4d8b4caefa6f5358c6456100001461c391bc5d89f1764c4495f75523196));
data[199] = Pairing.G1Point(uint256(0x056d50d5af72bc2b9f7e01b1d784ad01f0a6a184e175c27ce41d429df8fa055c), uint256(0x27fb521946339b7636679762de3fb3113150e80eb707ee0f6d647b4b08522a4a));
        
        Pairing.G1Point memory vk_x1 = Pairing.G1Point(m1, n1);
        for (uint i = 0; i < iinput.length; i++) {
            vk_x1 = Pairing.addition(vk_x1, Pairing.scalar_mul(data[i], uint(iinput[i])));
        }
        return (vk_x1.X,vk_x1.Y);
    }
}

pragma solidity ^0.6.1;
library GetVK600 {
    using Pairing for *;
    function getvk(uint m1, uint n1, uint32[] memory iinput) public view returns (uint x1, uint  y1) {
        Pairing.G1Point[] memory data = new Pairing.G1Point[](200);
        data[0] = Pairing.G1Point(uint256(0x0576d3433d2b134f1287f9c847eee03b7c74e6a0b064d9e6fb8e9db76630b40b), uint256(0x097d1e81066d2304796c0be05818bab18ae16edce5028dd8f86801c5e98ae812));
data[1] = Pairing.G1Point(uint256(0x017107b78f4dfb24dbf12f96c28f4ac95cff89053d1531e43dafb5971102d4a4), uint256(0x22785276fe84366e86a83857a44f490e5a82e071efc04a7561ba59b38afc995c));
data[2] = Pairing.G1Point(uint256(0x1744c663b26ee54b350d64d7eee7a1d1682e9b680177f24fe5716ef0acea0873), uint256(0x00262c8cd163dd35ac3283b2ffa709f8a6270b85f8068e7979c38b7d869bcb2a));
data[3] = Pairing.G1Point(uint256(0x0ffefd24cadd6fbe76b6592d632b73ff50a03a27521528c2c4272b61fdbf5bdf), uint256(0x14ebca175d88ddec809c70c5e0faed04f97054eea270d60fad1d143d4ef64e84));
data[4] = Pairing.G1Point(uint256(0x250980239f56f23ac75a6fb12b146583d037ec6377c72be01a98a2d26697367d), uint256(0x0cf6a0797eb7a3b2c72c1c172f026b8bed07ec3a2c6ac4fa00f8f8e304065fa1));
data[5] = Pairing.G1Point(uint256(0x218efb0670050f30c7260cba94ecddaac8ba23a079d5301ee5140734fc67c4fd), uint256(0x2a29e6e214c4814eb85e1eebb720d42a8176b7f0e24b3b5b021777a9ce165aa9));
data[6] = Pairing.G1Point(uint256(0x0517f83f330e40c67a4c72cdfc731e5d41a1f586b02e23b61e4c1a092748cf1a), uint256(0x1e3c90461ab62cc75f7dae02301d03ae74e73ca91d6557ae5ba524dd3cab6e94));
data[7] = Pairing.G1Point(uint256(0x189eaca55072eada0c9fd4f11379fd77b85e60931adf4c593d6508beb8b7305a), uint256(0x0013d3ffaa333cb23a7f219e0b397f559dcaf948f23d9dbb8b4db11ec24a0d51));
data[8] = Pairing.G1Point(uint256(0x1d46ff0c2811e1819e606be2179bf4b3e3a7b7b8be61a48caf9c1ae501d53ce3), uint256(0x12d1725973a0e6f8905da10e651835b268ced6da2d0b456a2137f97a3fd1f797));
data[9] = Pairing.G1Point(uint256(0x294575de974e6e70eb58600414a7ee72cd2369c37608e38baafe79ac1110eb39), uint256(0x27d3d490cad015e180b9957b5ee6ca7cc6e94711e6d512ddb50c081a00e88701));
data[10] = Pairing.G1Point(uint256(0x07b783d0424ab84ef0ba034cca91ac0837aed0800792364012b94ba95adf6a0e), uint256(0x05f6cd2a5b671a2f1e2af2e31e4285e2dac3ef311c3eea7c3b87aad04cca3d24));
data[11] = Pairing.G1Point(uint256(0x2e30650c405ccef461ea4d282072dd31d50a0fc26608141174417082e65f7290), uint256(0x1fc747659b8d0d4dba556a221a83455f303b1311cccf3ef263432522157fce93));
data[12] = Pairing.G1Point(uint256(0x2b3f5a1ed301b49343fa2b2fdf9afa36b2e998d1c2d66ab79c21364ea9790e88), uint256(0x242401ba4e24462bf8abeef16ee451bc925130ee69662ab00ed0175d151c8f53));
data[13] = Pairing.G1Point(uint256(0x070327e9657901235e4cae9770c5b6177acf4e4b174d6d03ba84aec47a217000), uint256(0x1164b76390da591e2236a1dcdc5e7dd3a23aac4ce1e67a8338201b0f8f321534));
data[14] = Pairing.G1Point(uint256(0x0a95872b0ca945145d7275a05cb30b9e1103c3396b0dfcf391d9ea8b0350944c), uint256(0x182833f3b98c4a1d4eccc352c53ee7d476fbbab00eb5e1a9f8921d0393178b4b));
data[15] = Pairing.G1Point(uint256(0x013b5384536b28e3f10a31b838509a317d4115e54e305f45e30e30b03014150c), uint256(0x2b95af5fd0a6d1fe87f0592e6e1485b2444d9bd4c30b47086731024b5189fe65));
data[16] = Pairing.G1Point(uint256(0x0842243a4fc081608f5a460f3665a51239d2e5db264ca41c9ee3c2a7e52c4855), uint256(0x05476d7112e96cc8ea969fb6b920b208295932dd0be6ebc43df98c46c2e79773));
data[17] = Pairing.G1Point(uint256(0x2b77940b1936123210ba2ef41d613acebe939daae0325f923acd17ee0f64bf9e), uint256(0x15225c6ed40c6ca8c39cc656daf544b45c67219a99ea3f7f3ee503200818dc17));
data[18] = Pairing.G1Point(uint256(0x237b66e0d2468ec35d3f759ae016d53eafff7b4ddecf84fd302e4c8cc7826747), uint256(0x079213d8b5e07aca5ddafd9a627ff003b0cef743a3aebb636e749e94a3c77dab));
data[19] = Pairing.G1Point(uint256(0x2b1f2d34e4eb38d244e26fcd4f1c7dbdbcc4311e09534dc24e42350b29f0d97c), uint256(0x27096fc0b37e446d6427aef3d240bffac6b12c459ac6e6e477c11fc8bfec09bf));
data[20] = Pairing.G1Point(uint256(0x0c1332a87c996079d4df6eb93246f991c62c800097d76c94fada016f86189846), uint256(0x1c33fdb9105fcf791edb98673a70e40d156c40298915e7159d5adf962a50f490));
data[21] = Pairing.G1Point(uint256(0x0d4acc46e60512e704ca60d816ce6186aa600e85a3e60014138cb47ef8aae7f9), uint256(0x04df99e50dfac17eaf748be3b466f8aab211027518a95d3a200559583e583c9f));
data[22] = Pairing.G1Point(uint256(0x1cab2133e07b81d67e935c472d9efcebeff254701a3fd23f8b9e06c035614a4a), uint256(0x071ead53cff0983568e2c83f3d083dcc772bddf53ea752b09bc044931576a2ab));
data[23] = Pairing.G1Point(uint256(0x00be830a7352e4114a7d97bfaa74b836bd202294a35f908e96230214781a9861), uint256(0x053d182d25f60583acff0bdf96ad6e900f8053eff8968e561098a6ea042f08ca));
data[24] = Pairing.G1Point(uint256(0x223506752281e55b85394ba192792e00a65d82a82091a1a25e2e02046841a5ea), uint256(0x0df4ea8236c22a65ebf65be791c44fb921c3637493b3ff3bf13ba58368677b0b));
data[25] = Pairing.G1Point(uint256(0x1a083af442ef48f4f45fa0d56a5d1df8d8d0364727cf7fa5f273a37a66e9c36c), uint256(0x25950d16e9f3c1cac09969b44f1e6b7a0140bcafd9e2d7c161e5babb93c471eb));
data[26] = Pairing.G1Point(uint256(0x2fe58c64f2fcde731f32bbb09eca706e01d698885bcd39952e9c74402c18dc37), uint256(0x214bff7e27e7fcb040a92a7bf76096c768674e199d896ae5156c50e0af31feb5));
data[27] = Pairing.G1Point(uint256(0x02d99eeb6acd1e1204a03509e3607db5e14da63c2bd62f466b7c2dfca48ac652), uint256(0x1071991a920948f949f3705611bb031780b3726556b12542c0c404c591e3d1a4));
data[28] = Pairing.G1Point(uint256(0x2bf72bce6cd3ff7452507836cf87f6cb8f791749093a5f64eaa777d4e5128c72), uint256(0x2e816d99699d9fc35985ba851f73f8c7c15f3d0d041ecc0776a69ac854800271));
data[29] = Pairing.G1Point(uint256(0x25e440c2b4569c28aad3d483648ace95d0c7067d6ba2178cfd4428c4e6cb2dda), uint256(0x0103acdbedfacd0b8ef7f31473602334ae93ca66583bcf921cc2f8eae0e3ee1a));
data[30] = Pairing.G1Point(uint256(0x2f50b0fd5129f31d18e347836d2c7ddf163d7b6b07cb4f7fe5c1d33846ad46fa), uint256(0x238fc8aac43c1d7f8ae42fcd74ed1712a0f659e84eb8b8d20b9921cb985076d3));
data[31] = Pairing.G1Point(uint256(0x19976fed1042d344a918298c739c4173479e42263edc5510530207801eabc65e), uint256(0x15aa2073fd90ce197596fc8c0fcab61e3c3c2f572bda1c47bc735d3bb0e370b0));
data[32] = Pairing.G1Point(uint256(0x1d2cb94f21e9084573d3f4efede17fb1861ef802949be796dd9e667d29440999), uint256(0x091e05ba1c63f26510ece25e136d1c888263fd4ab1bd323d6eb718d47df7de4e));
data[33] = Pairing.G1Point(uint256(0x1b164c79706b6d6d1026814ab1f58a0b0ff82b027e831139d027bd297c7945de), uint256(0x19743d21da39a5a7e7ce6f868d87e980c16912189ff54964d5a8fbdfa03052e9));
data[34] = Pairing.G1Point(uint256(0x2c4908f666c07ca453df3bc6d3a9658c56bf2a19f400e4c7e736a88893f0d397), uint256(0x2a88769e79891f8a61d72d71c8911f7849ba23ddf326d8a287de62085ec89097));
data[35] = Pairing.G1Point(uint256(0x0ac344b26c2c50bf353c59b327cade6d1154d031e5aae010f115e846d423edff), uint256(0x1dc1511374214496edadcc71a9658860c3aff159651d18ba8fa17198cec92b0b));
data[36] = Pairing.G1Point(uint256(0x2db72ecd4e9966730ead98a96a0f9ad0af735350c91c75caea2ec0f016e1b678), uint256(0x05cd05d72b862c0cf70eb4ad125ef7e1a3964a33fbcf51a64c12dd93ed04b77f));
data[37] = Pairing.G1Point(uint256(0x26e0d2fc3016f33a80e885df1c7494e2a5a84b5249055064c2b9c3ec0a2c2606), uint256(0x0b79c0f11dca668d6ff2c0963deec63d0b1cd281f19c5cc1f2012d829178ec2a));
data[38] = Pairing.G1Point(uint256(0x1223f946bff149b0c62454e7248d3c64a73440ab38c183ce03ed328eaa5db333), uint256(0x071b6a22d21208811ae8216537980805c922d7c3eca62ef80aa28de6b98ebf30));
data[39] = Pairing.G1Point(uint256(0x04d2989413fec11324887f4a272a331099b2afb9034f065284edbe5d25984691), uint256(0x11d415a9206213a6dcaf749759f983acacdeba9be83a4f0ece5ca980d884904c));
data[40] = Pairing.G1Point(uint256(0x240d084e073c692215f1a4b97a52fea4a80654537e572f7d4f01de7424458f43), uint256(0x05e776fb8235abe7080579cd747875b8d5f6e3ad6eacc3d89b25e0b5aa787b73));
data[41] = Pairing.G1Point(uint256(0x069180313a62125e28808bceaf74a354645e10a3481db6824cddf747a06dd4d5), uint256(0x290983ab2878e0412470e532d76c8ad612880eb457b69d9f17d242f903b6d10d));
data[42] = Pairing.G1Point(uint256(0x1334459671253d62547d23eb987ebb58a7086a049c46a3beca76e804543298bb), uint256(0x0492ca86030e3bc892d223528ab721efe764062f7526524fcaf8843e903bbfa1));
data[43] = Pairing.G1Point(uint256(0x08458e09536a87f939a53fc07261e9a17a457ee7ebaff01977569077febc2662), uint256(0x24dcb69abf90db61d974d0948331bf6fe649489c3b64ada6a1a1a832817c9745));
data[44] = Pairing.G1Point(uint256(0x185f0e09b5040283f3cbdc9ccd876250d23b250d7355a3a686375773146cce89), uint256(0x25d3a07fcf4a6a6d07cc3b262e004b5f32b1e7aa8198ce1a15c017ffe03aa108));
data[45] = Pairing.G1Point(uint256(0x1cfea85e8658ad1964e34368115e4753a4f9cc0f169c9cb16aea13eb1a8424be), uint256(0x150a60b2a6ad4cbb309d18ab81c599602f41b1e8fc0195557cf15a1edb8d3731));
data[46] = Pairing.G1Point(uint256(0x1c057f2795c8e7de5ab153a285c93e54170cda8a003dd468cef9a66a6b93ba80), uint256(0x2d24eb4a5b62d372ed7ad0cda9fc41b1410ca1f9933b56c3e1d8e90fc14ec739));
data[47] = Pairing.G1Point(uint256(0x18908ce6074feab837671de68f620a129629a14d85e30faa44d6c9260478c24a), uint256(0x15f3e41198c9f300a403b256998911f8980caf24eb03ffaeece66a5a9a680d55));
data[48] = Pairing.G1Point(uint256(0x2defaf2042fd91663e0842edb2e7dada5b9e72c7204fe4fac4ad90b5b218fc13), uint256(0x2f92967c36f92fcea95e8d834dd95442bf427de7dfa5d998ba9ff8037632901b));
data[49] = Pairing.G1Point(uint256(0x278b88324c5edc206eba73f7c750c4a4d4c400f667e9f0c2f45f4fd7f4e35eb3), uint256(0x1cd21f7aca355a72746483c7eca5cb34256afcb01458a9cc5f04331db1be7a57));
data[50] = Pairing.G1Point(uint256(0x2bd193a82aecc710945c30c75c86923b3273dd4b38f102893aa2ad5226bcb7a4), uint256(0x2bce323b682947aa6a2cf8408d28657fc41fe652a1e4c24e128c4b1544825c07));
data[51] = Pairing.G1Point(uint256(0x212d3e72a0db0528a3e23e7c903b832e54664fb6c0b4d433edfed659afe75f59), uint256(0x20716ff71fe39ab00b06da6b53bcfe2dcdd216f08210ff37586710d14c1aadcc));
data[52] = Pairing.G1Point(uint256(0x0a2cf09a87fa0faf56d0db0518c8351b923594982261b96afa8633938f930063), uint256(0x03efb282ce7914efd71ad5a46cf4012e950d50121911c1d518c55d9a7550b27a));
data[53] = Pairing.G1Point(uint256(0x120a2abc046c0d0dfcee7bc39152a470b363bccff90e7e82afd8ab642bfbc5fa), uint256(0x0138c921a8905207f6dfd08bc391e71c7f4bfca30538a7ae6078e2e34bfacf79));
data[54] = Pairing.G1Point(uint256(0x1329aa74c73a948b42c93663ee8df49f6f5907bdb6bfbbc66a9122612e2eb452), uint256(0x2a06d6a0e4e66ad5c26b4a1cfda95a5b68f6800c9df1835c6d6efdec4ead64c5));
data[55] = Pairing.G1Point(uint256(0x004f4c01278eea74aee85445aec7394e05a6ced7c05f65d255e1d30ac5f3b033), uint256(0x050fa66aa4e9c0849b7badafba65b2254a9a7d53ae5bf59272e1aca02ca1df4f));
data[56] = Pairing.G1Point(uint256(0x25738e417adf6d55f27ea4971a761f7438a98012df0336e086d7ff4cc608e8cc), uint256(0x2cb93c975e6b94a232ba11ba86e238ab3ad110a5e8a76f7b3284167003b5e847));
data[57] = Pairing.G1Point(uint256(0x2158ef05b6bbd0c0bbd8251c3633995d49144493e2db3955f5bec1ef3148b7bc), uint256(0x2f520c70c36bd2cd0ae9ab62a74ae73ff01904284542f50699477ff1c584fdbb));
data[58] = Pairing.G1Point(uint256(0x2f27f348a595945ab8d693a2cbf2226983f3196e8ca91486acb614b36fb93d17), uint256(0x0bbcee309c43c156c8dad6ad328d9fb86c15957de0444fdc07511f87c18492a2));
data[59] = Pairing.G1Point(uint256(0x26ee9b9ec9fca2cd34100c0c2f3639f5f0a249c57a8adffaaad7e2047aa1dc92), uint256(0x20265bf57ae4d815f89d3dc3d0847c5869aadb3e315cae40b4ff8a885e28e7fb));
data[60] = Pairing.G1Point(uint256(0x2924737067365df3c6d2d7cccdeeea27ce9a129246c18f34f9c1279296aa796c), uint256(0x060f6e4818d7d1b84bae434dbdccb80ba7a44af7949b3efcecc94769726c2b8e));
data[61] = Pairing.G1Point(uint256(0x20db189744158c5c6738df584be457138e684591ca99e373379c251dc3f5084a), uint256(0x1d0eee89003c64aa9bb4b2a0ee9124a12c86258f799341bfc4ee5d802171fb93));
data[62] = Pairing.G1Point(uint256(0x02b7db63466262b17d911e5abc2a1c0a6d95a003d28193bbf6c0f1ebbc33fac9), uint256(0x2d3cee3b55b6937a5764b53c327c0d0e186b87d1563cbd0f1512cc019537bf4f));
data[63] = Pairing.G1Point(uint256(0x2ca023cc316ae914500c53fd9e8167c713280592fdc46cfe84e3b376e1522911), uint256(0x03fe6b36153eae4d0932223cb05e13de433db2e36e5056edb6e592cb8eca5e0b));
data[64] = Pairing.G1Point(uint256(0x11d4305774aee9dc943fcdb52b188df46abeda8dc2da32e2198495ef0c5f13c4), uint256(0x22cb2cc9cb4e33d1a4921d147f9f53db67d09b0fccb390df2ca738e1fac8a4ba));
data[65] = Pairing.G1Point(uint256(0x2bb8fc94dbe714a6748f5967f7825d17b1c51b5908f41f667c6199a2d79fb328), uint256(0x12bef13590aedebb5e7710c6a49905d1d9c27d8421b1e8a78e3b464a1efd83ae));
data[66] = Pairing.G1Point(uint256(0x2d73fe1310653bc4cfd765c2272e6b6ee5e38c92bd48da61816c841474d1670d), uint256(0x0f84d802a01b0b3d703397d7db0dacea4e9ab1fa9dee1cb7db382bb8abd05fd5));
data[67] = Pairing.G1Point(uint256(0x2bc28e6661ffee6a25a08eb8897564097bc13424dceb7f638e983ba347f358b4), uint256(0x0cd4e67f1723ae3219124ea1c1a96c80c04deeb7b7b0c07f40f28603f9a38ce3));
data[68] = Pairing.G1Point(uint256(0x0a1a2d017efbad3de5de5bb13e545f8b1ba6f678716fb9fbed7528779635debc), uint256(0x0042af591bfded58f3f5628a369fc45a140757629324370e01f65dc276028e76));
data[69] = Pairing.G1Point(uint256(0x10b24945fc95ad825c074e0a52f6821e767fd6fd4a0d63ec423a603de05078a5), uint256(0x26b3041f4461bbad6388eae5af4d985541c5a35ea8564098fd3b3522882f6be6));
data[70] = Pairing.G1Point(uint256(0x282f2f3976e95854b770b4bbe31b3cbf6f4c4e2774f5c7dea6a0715607ea2a03), uint256(0x0ae2591d614aebdfb280a495b30d1d556088a4fc2cfe4afa8ccabb1d95f5cbb8));
data[71] = Pairing.G1Point(uint256(0x07783c3baac700c2bf6d643f49bcb6803ae26139f286e09547fb790381c7f616), uint256(0x26f823b6e2d1b954ca614bcd5b7999a0a3febea75c315a4435b97d417572ddbb));
data[72] = Pairing.G1Point(uint256(0x0ab2c2216188f69c5c72e28f0a131d0c180fa52f8f47174ca143520d6eba8046), uint256(0x0c05d78567160ad907cebe952216d1fed62a26b65f23bc26b59ced0308c7558b));
data[73] = Pairing.G1Point(uint256(0x02a2d40683992306174d7aba3c89453ef36f84fdff64eff09fd57422b05c6c09), uint256(0x1ba66849701c513bd7f5775b7d31ff66b61443a585ed594317e4d05135adb8c3));
data[74] = Pairing.G1Point(uint256(0x07514a5fa8d697beae5b1d219d6afbb959f8b4fd9c0d4c7f4258955a8a5f9f96), uint256(0x08d9bc7433afbec4859cd3e518f55eed92442d9d7825cf572f1ffa71e76e087d));
data[75] = Pairing.G1Point(uint256(0x0f0684a4da7eef61e7499640dbc95943be85a4bbd63bb32b359ee2c8bb91c4d2), uint256(0x2156c317412eec17879510c55f5af7ff39b097bea389025d9fcc1799448ec9fc));
data[76] = Pairing.G1Point(uint256(0x248a13144ac86ee9834b96640d56f5b0769a3c59b7bea92ab7302119501576a8), uint256(0x0859ab4e4e94550ff2bf1e46c5316ba5812525026de1ae84ca5b3f4625ec9c43));
data[77] = Pairing.G1Point(uint256(0x0a3ef96d3d578af2b7ee495cbf5a702e432ae59207b1ee4579532fb82da5bb1e), uint256(0x0c70b7a4a06a03263321640fa0b144caff3a521932ea76ebff6f4037d2b45902));
data[78] = Pairing.G1Point(uint256(0x10be299c78c6ae87caf77efb8226a58f422b780fbb79470e8db144728c4d5131), uint256(0x0dd70d98785373df94394163d8a3324379ad9cc3049fb36f37f99c9dac3f1822));
data[79] = Pairing.G1Point(uint256(0x281bf2ffa2ad8e572e72f02c99e61b9be08434e54e4098978f7c69cbf8734c1f), uint256(0x1068af0fe3a95d88c79cb52188c66d04e2e1f7ac52ebe13a40f1f42cc0e87b70));
data[80] = Pairing.G1Point(uint256(0x10f705f0dd85e758062f9632a09996cc38898d1b3948b996ef5b769bcb2d941e), uint256(0x08de849246661fcfbcd1766c4c1e1776556d5678089772dda9f3f6f15daef300));
data[81] = Pairing.G1Point(uint256(0x2641e72dc4215034d71041e439d1e34d190aa72d29f3e550fce421c94625608c), uint256(0x0dbc15f8f6b91da1af4431ea45fb67a240f306a6d899a45bf7ddd8bf34cdf0c7));
data[82] = Pairing.G1Point(uint256(0x00dca368c91cecfb1a08ee2201f74649046c5a0574b6f41737220b8c377cec9d), uint256(0x0ab919e7fb09372f87d11c08982dbd85289c311cdb1edc566dd2ffb3aaa0ef2d));
data[83] = Pairing.G1Point(uint256(0x0d5ad3bed3adc322f325d633149dbce776e98ca40b680d2613082ea9f9243792), uint256(0x03b1f2c0fd76f50bac5874a7b6b0640702d0fffa8a08cc7fe1782e323e9150cc));
data[84] = Pairing.G1Point(uint256(0x004d0cd9acf8d87cc56824a4b14b96894f02be0e84f6f99830c5ce671ab8f646), uint256(0x08d34ca9569e55bcda1d641bc6d783504b2edef9c83a12959300e4e2e145b84b));
data[85] = Pairing.G1Point(uint256(0x048b2546f1a6a55944328c73ea3f2759128a9e08d3085725e83c8adabbed7123), uint256(0x121f3c3ccb8da2e1be52a82fc78fbb69389df748b575a92180cfcba8fea77f7a));
data[86] = Pairing.G1Point(uint256(0x050e8fa4d67d33c781236db137cd3d61252dda3837d49220027abf2d6efaabda), uint256(0x243751a0903a16f6388199355506a6badc77a2d7fbdc7f6e203f244855887396));
data[87] = Pairing.G1Point(uint256(0x1cc0175a792ecd9ca80113f1bd3e492ff6a7e29e88669ce921d8b9b4a5fd42b7), uint256(0x0a05fcfa6c03e9ae0aeb6935cf86ecf8ac32bff0136b65f81204bd1c0a5ae376));
data[88] = Pairing.G1Point(uint256(0x07adf091083dd9eef8e580659c0855e947ca478772a19429b01f7b3354214435), uint256(0x07416b77f4b244e95d8a3a561cf675048183c0c7c1a54262aafe38d24b6edd20));
data[89] = Pairing.G1Point(uint256(0x0b26e3df1057b470b7ff8ccabec6b8730d54de0745cb5741601b2d98dc21b277), uint256(0x0983338f8d04150d1adf75a51b85fa19f0f894ba09210334f09c878685bcda10));
data[90] = Pairing.G1Point(uint256(0x09bb8d3f91ee3dcd153e763d2301adedadfb707b3bebcf2925627b7605ef042a), uint256(0x190cbc03e3eb9f52c3adfb53e4753646bc1453d06c0dc4e7060800f795d403d9));
data[91] = Pairing.G1Point(uint256(0x11b640bdabdc6bd212cf8257ea95f0af706752643f4ef024a5f97428541d7f05), uint256(0x25452460aedac01437841d5871d8c5081edd28b1c425d88951d3a5f995a41684));
data[92] = Pairing.G1Point(uint256(0x0636bad4d6c7a3fcfc6e9bbf0656a4d4f6b46216d70ec2a1f1be41e9a88b6684), uint256(0x1ff66f89165dc59a797c687ff2c455bf7375ac0adeac187f8d68c4881b71299b));
data[93] = Pairing.G1Point(uint256(0x298311a3cfa6683bb30176bc1c2149e67bdf5cb0343452263514f295ef6a3801), uint256(0x123f0c4999bea55bb525e02d26abb607289823886c9f1f4f5a84be6628bc5d98));
data[94] = Pairing.G1Point(uint256(0x09cc68526a302fb50ef55f657f51765fdcad3a977922498fc682314d6ba8f875), uint256(0x0fecd450e6f61ddfd9d82ee4fd2c4e58b5a3152102fed97d78227a6691abf49d));
data[95] = Pairing.G1Point(uint256(0x2d376eaad6641af2a59f47c329c4da7c7f7eb25a69df3eeb83065aa144e197ed), uint256(0x06b2445825c9db16cdff0f64a8d49cefd84aba610a7f1d265bbb0703b4342a52));
data[96] = Pairing.G1Point(uint256(0x20564f8f1bc567c9ccc09b3a9699616801f090e004bda5c6506b0dbff837c394), uint256(0x2c65da819bea99d2e5d60c7293f29cbcedc81e930c40bd17f53427d338de1f23));
data[97] = Pairing.G1Point(uint256(0x163e3d8efb9aea90785e9392866f23b9e175533f7809f24247d3f7775726def7), uint256(0x2a339881fafc4e25e0183ef887ff73f19c82c3e1007ef6c52518563ef04c76fc));
data[98] = Pairing.G1Point(uint256(0x2be5bf7fee15f0a3bb241e5c7c70cfeb05e63b47b9b29b9096e3398f0b463998), uint256(0x2752ea19c3c556be564fba47df4b5ed3f39964b2b20847ab57cd3bbdfdea0bf6));
data[99] = Pairing.G1Point(uint256(0x203e8c09172b7604c2d24f6f199824ddba0a914d634674422387d1cd6bbcf681), uint256(0x090e4f254a3bbbf4b6a99e24da80ff8d118b5ddf7d9e8c9f5d32526e6402542b));
data[100] = Pairing.G1Point(uint256(0x137a960d78214a0acb8401999f3b3c4a382fdcfcb575c9ada4445495c720e1e5), uint256(0x230db2b36cd5adc338735bd74363c119a19d3df1a107b0e228973f1857881258));
data[101] = Pairing.G1Point(uint256(0x04d03c79b4e7726d9f92a4cbcea0036778b9fa4611347f9dc8f9a216dd999474), uint256(0x2a19971f55514e30b20c5395f76b5fd3c23cb696918e8cbb51a965563926c669));
data[102] = Pairing.G1Point(uint256(0x05dae0fb5819e72e957699b1877d6fc27b55b1f74e6f7f73c218cbaa6262d731), uint256(0x0da2a7296082355bd00b9f45c9fbb622f4c8a21e1adbec90b8f89b882141d670));
data[103] = Pairing.G1Point(uint256(0x1d780dd255f79f17154efeb18729e4ae152d8388c79a8b95f601fb0ba72ab475), uint256(0x1cd7312defa695d644c9a98d995cdaa2efe847c1e0fb146ed3028a1480fcdde1));
data[104] = Pairing.G1Point(uint256(0x214010e998e3068537b86bda84e4985c4a9094421f3564bc278c5922e4a65b53), uint256(0x05a9cdf9fa348e4808c3a5b2e9f73b7ec318458d232738ec87bb1d0c21e50225));
data[105] = Pairing.G1Point(uint256(0x170d3aaf94a8d0e54d177a129bdc381f298802469c680171bf035026b40a9b62), uint256(0x2f1f30f189e8f78c6cdb0fda7721fd8f4a8cf1d01a742dc7a147fa25877ab176));
data[106] = Pairing.G1Point(uint256(0x28177aece1c8ec44a8996aa3c4b56a0e09c7a262e9a44a4cc123abcbb6119277), uint256(0x1739627c65793b83b70dd7dd36e90ab883deb5c79ef20f7a6f018fa1d9626a06));
data[107] = Pairing.G1Point(uint256(0x0498440d5f72c527371fbcef24a504b433d18c15a0d2ea5adb96551bf8eae841), uint256(0x0763dfc899f65ad5dadccbe5271bd12948718a5d5dfc99901205dbd41f49da3b));
data[108] = Pairing.G1Point(uint256(0x0f1431eaedeb1a6d2896e868dc47f671986aef262cddb681262775bd1c49e7be), uint256(0x23f8d26481b1d577479c6dde5ae85ee48df6cf5bdde98dd183d38d14a6d1e4ba));
data[109] = Pairing.G1Point(uint256(0x24a59ef499c57332fadcf243baa12cb11facfdebf1ab15b594a674aa02cff361), uint256(0x0deb6809123687c08cd9caa01cae4e1ec5a7525063a175ba4ff22dcf70fcd446));
data[110] = Pairing.G1Point(uint256(0x268b93bfbb8f13e2b737d9e0cd82179801aac560935423110280336e4dfafa12), uint256(0x28d6fb27d2994318e7d06a71cd05ee73504a269d82a071c1864d0d8464417c3d));
data[111] = Pairing.G1Point(uint256(0x002a9ca34087988df753d06d2a72b7637f1d6f066f95837d452cb34f4d6c368a), uint256(0x2af981709ffb43212a2688e3c150ba87eaa22f46dd062673a7602cd8d7d9b803));
data[112] = Pairing.G1Point(uint256(0x22a62742566655cfe7c08394cd2827f5f0e9f420e30de5f79ee48766b71af463), uint256(0x1ebdfc88e21d42fb4d5d852944113e17017064e3726434ee77dff67847772677));
data[113] = Pairing.G1Point(uint256(0x08f5da30a8c6bd8987081ffe17bd38e2b22ddb5ca93671b704bac2cf92daa750), uint256(0x2a397545bbe772b46275878ecc9cad9f10a9ee9a5181f346cad7cfd5f7574ce3));
data[114] = Pairing.G1Point(uint256(0x269bb5fbfc123fbeb29b573a83bb3a9ab047bfc90493df3bfb37a25487a7adc1), uint256(0x2484cb28ecebbe4d747540a5a349f8014d04defab9cf44faa5c9bef43cacc706));
data[115] = Pairing.G1Point(uint256(0x0295fefa0b12ff334bbe0c4e43565233aaf0720d80a0a77905a92480f2634c73), uint256(0x13be6687180dd4fbdbccc4a24131dd9f96936ba8d2871c29c6735a173db1df6f));
data[116] = Pairing.G1Point(uint256(0x06d637e499f7e3e4725715113608bdb63e8ce0351733cec1d4d8cd69499a3373), uint256(0x06eccc3fc658446b7ea3aec5e55cfb32abccf698784b8cbc21a945f3deda979c));
data[117] = Pairing.G1Point(uint256(0x19cab186e100c797a2b7c428436d4f2eba48c9aa20cca790a91376eb83587f21), uint256(0x084c5275acfac4d3a00679d95e0a81efd0874bfb9d88e555e255372c79a1703a));
data[118] = Pairing.G1Point(uint256(0x1ca3b5690e42dbd16bf61c34270d1afc6bb8442bca4d8750c7118f8985900973), uint256(0x2df53bba1e7bf85f483f596436ca78c1306c4172281ba63f24f8229759f18c8b));
data[119] = Pairing.G1Point(uint256(0x2568ef35a64a0289b72a19cde79219e78056003df54e30b753fa8f1e970f6b16), uint256(0x16436f424d1568d9346b19cc69a1dd015b2b9b27d3554ea4bf0443df66350bfc));
data[120] = Pairing.G1Point(uint256(0x1a218bc6e653d0e0cdecb76da2d7672a4656f7d66a7a9e8ebe26c75d98b69bc5), uint256(0x1cee768653120ad959ffc714e14cc4548769c59f8ac271ce003888dcabd398db));
data[121] = Pairing.G1Point(uint256(0x17f2c1d1012b1a959a6c49f65834fe488126dc5c44c2f3f39474e645ff1b481e), uint256(0x0e7a5642719d64838b4d38f5dda0e99acfbdb86a6bce844df6181e1f87f94ab5));
data[122] = Pairing.G1Point(uint256(0x2f9350358c929698013ea0e67f87617092e5bcd368175c78f1b5fddd8c29242f), uint256(0x2b5ddfa1c6e4a00c55469d0d9c5991bd3920a4785b7a42ee03afbce7f9920cdf));
data[123] = Pairing.G1Point(uint256(0x094f03a9c85d3b7435b211e054d3c03da8e76ad8434ce3dd6ba67b98b95eb6c9), uint256(0x2a21be3a109be3975a219c5d0ea661b3fbb7a55cc97a4dde4f8636db4bdc94b5));
data[124] = Pairing.G1Point(uint256(0x16fdceaabc539b85bf913eb775c105ad9117526e48e43357a4900da4f5aaaf7f), uint256(0x17d0fdb55d3563c39d0c879ebebd16dcfa9fd277201c6023aa8cc0b555b71c3c));
data[125] = Pairing.G1Point(uint256(0x0387dafaf727d87a42afc7faf7e583d5b2d4d28ce8e2c7d028aeb229a56abdd3), uint256(0x2712badc43a5e29857102cd822061b4a65bdc347af547fcb3c051ab45e7112a4));
data[126] = Pairing.G1Point(uint256(0x1b0fbae2b35fe918ff9c109a9f8c7ff6c142866e264db4b00a21184d27c7eb99), uint256(0x1c5139b1e660679f71a9c1f9e1721cbb8a6244ce2e3a0470d31c5bddf9ce051b));
data[127] = Pairing.G1Point(uint256(0x1ac5187c59171b426271ec5517133b5ac1e34f8d4b66f3a032069b8420c9450b), uint256(0x2f926c1750aa68e5dbe568d249eae4069527d284d1b0306351b4ce7e50680e52));
data[128] = Pairing.G1Point(uint256(0x108e82a48b09bdca98e5bc1661da9f892c51cd7ed8a32e5e8aa999085ac1dfc7), uint256(0x23ee3aacfa2d7d6cebc26244411f0bbb2eefd36155d8a1894bf7009eff001cfb));
data[129] = Pairing.G1Point(uint256(0x1db2ab9f397ad43221a4aef4bd5f2b710e4998f65dcddb68487f5ca690d5ae99), uint256(0x0e95e4964ece800a73981a0cf6a409634bd284466cfb12778c0032a9253bc42d));
data[130] = Pairing.G1Point(uint256(0x0e3ce341769942d68ea6faa89b27397b69e45d9b8b003c360136c631f66376bd), uint256(0x0b7967582a70bdf2684f4f7193f93c747892be00666ed343c4da520bb3185301));
data[131] = Pairing.G1Point(uint256(0x1f54720a1c961e655523be7572450a993333475ebf5655e2e3c2c4f0c89121ed), uint256(0x1a5215b3d58a7858ea5c8be32f0f0acb601979c515fa8f5c1985e5cd64b7412d));
data[132] = Pairing.G1Point(uint256(0x1558982efb5e015ff2234a6fd85f0566046b1e72c69f0cd296252ae6b3fe6e20), uint256(0x2f0c1699cac09d495c9d37fc6401e8654bfee562801f074e0f7cd2463e125e3c));
data[133] = Pairing.G1Point(uint256(0x10bdb265e0df8d22809b64e1e879aecde59713cfb349f07267eb136cbef02fa7), uint256(0x0dfd449064c1d627cd94b192a0c06bb9d7b5de072c8216b9bc9b4572446d8040));
data[134] = Pairing.G1Point(uint256(0x1005121ab024cdc84e65a4a1bf221ab6b35d0bbb32a033399f306dde2694ec2a), uint256(0x17ae3b29608172b59b3f4bff973bf409d3d50cbd56229d81817246afdd4a555d));
data[135] = Pairing.G1Point(uint256(0x29c42ba185777b7795d57267fa8a5050bfc2b0368c5b36591bdda42010580ead), uint256(0x0047bc86aad57c30ecbd9da1edc4545c8bb9224632ba6f2b73d3f45775176a66));
data[136] = Pairing.G1Point(uint256(0x26e89a38420549f2fd69c143fe07c5422a72666091d8c44d1f013274f5225733), uint256(0x176b01c38ea32de9413c0b9f622ad17c2b9f8f547e3d2d5ffbb6c4c978feb5e1));
data[137] = Pairing.G1Point(uint256(0x01ecee5e0e74236f226d921aa0e1dc19d9189df3bfc971ce6baf1d79c1e57efe), uint256(0x17beb8ef5d865ec75fc0867b258d88f2df7120c288a7d464e869af2366746e21));
data[138] = Pairing.G1Point(uint256(0x22c14893f72acee3bc078c7ebe075de405c85e948377d04ec9c1ece4e5a202a6), uint256(0x233869d3e6872170a0a52105d1039ff0f8319baea79b4aaa5aeebcc56bb3d76f));
data[139] = Pairing.G1Point(uint256(0x0638322bf435870ae1370e61dbf4162e3a7bee345795806389f8a54d0cb6175c), uint256(0x23ee27653216f2af5d4e26297b8090fa15cfb843243dc6a6e86745d716a4eaeb));
data[140] = Pairing.G1Point(uint256(0x1f43f86253db3622ec109340d29645f293a7c9726e1bf984b2f64b1ba5155470), uint256(0x10c28adafec1b4795cde77f18fd60e873a04b1cfd2c7469e0ac7a2ea2fae2592));
data[141] = Pairing.G1Point(uint256(0x200ea10d4d63ad5c3d7c04186beeb05e5867fd4bec7180eb59c99a73dac41e10), uint256(0x0233d554db20a8ab4663eff88eee721053f82d0b5d1daa1ce205ecfb331dc15a));
data[142] = Pairing.G1Point(uint256(0x0a62f475ae54e65ff050d25e62fe8ddce4598d18152f6ed4c523b6415f7f048f), uint256(0x2f5aef374c142681d9c24c580fb3eb7d69e231a24d304f14e4b7dd28a0de6eee));
data[143] = Pairing.G1Point(uint256(0x2c8f8013be7c37ab3e438ed5f2393f2bb88223c99bbf6d997dd7b2fd710c1f74), uint256(0x1cf7e37a5e74dc818fea7762172b2d93cf4f65b47f7f14b6b839bda3dfae35cd));
data[144] = Pairing.G1Point(uint256(0x16789225af4a9609ba0b1755af28877e7cbdbbe54821097d4fd26db2c60d51d9), uint256(0x19a05001abe5b538cab60781364489fbd35de7f0561144c92112679ae3f4474f));
data[145] = Pairing.G1Point(uint256(0x034d9d3b7284f47a6deb1429ed026cb01c31af8d40bc008059dc5e0994bb8984), uint256(0x1037c06eeeb42f5be95ce38079234ad53c3519e14eb6b40266ecf5ccbe8e113e));
data[146] = Pairing.G1Point(uint256(0x305546959640056917dc542b79ab7a5ed8861e339100f5d3d26ed8f6f36d47c5), uint256(0x2a5f4939df81a665e1809d5a0bf8cf280278eb3eb9f55dbe5ed6fa760dc393b0));
data[147] = Pairing.G1Point(uint256(0x0ea8fafff507865db267e330c330a481804d3a5ef6729fdf7b1e243fd4adcc9a), uint256(0x2e97c6deda9cb489ab8c4026edda885ce3739e3b892fb126f160341f86d703ba));
data[148] = Pairing.G1Point(uint256(0x1df92fff92d19d50df69c1ab2e5ac6e8abbd1041352a89afd301569ec358d742), uint256(0x2f07e9d53745103e80fc2abda25242ecbac619cfd6e4093c30da5411f63db61c));
data[149] = Pairing.G1Point(uint256(0x20477609279d75ea88f8a304253852f005cb1d13bef4642b2aa1ae4fe063f992), uint256(0x2974d3a96f1676fdb8708ae58512be497572727c2bf86c36e2a70239439aff3b));
data[150] = Pairing.G1Point(uint256(0x072d344af42d5c19486225d9d628dbad20a23232eeb8e29b97de5ed637ae6da1), uint256(0x29c33f21a5b164c3bd7414502aa22b3907abb7bd7d3f4c8374b3d5b68923a934));
data[151] = Pairing.G1Point(uint256(0x06b8f2004869d63ecb26f12eb95e8315e879200ebdcb3508e852b83e83a65586), uint256(0x18aa03a9ff7bb84b424b31f81e9ec33340d931d7cebf867f5d30932c5b2e63b1));
data[152] = Pairing.G1Point(uint256(0x2c68a4a566ebed3aef5b8f3da30370616d166c1102bd1f70a4bf58203fb9df1b), uint256(0x1a99087505258d8bc2e8d18f0c3810fca97d184cddf5343298d01fecc50936ea));
data[153] = Pairing.G1Point(uint256(0x0926a5b98eee0afd5ccfcb2ba50c6eb4d4573ae9d6cc42a192f3f50f87c434ad), uint256(0x25519eb8cf0efa8a653a54926b03851bc83d3ef665bd1b5c4d271ced80aa0d92));
data[154] = Pairing.G1Point(uint256(0x08faaba111e5aa9b772c93a3494e6f2d19403a7d2951b7940194b90224091d08), uint256(0x217f9ac5c87816899512518cb4acc1da811f79fa36994fe59e3f6f0252424264));
data[155] = Pairing.G1Point(uint256(0x1905b56afcd0dfe35a20358ff863ad78fb5e842621fdd904f9423cc4244b4de7), uint256(0x20d0d06f27a1935fe7668e37771e6925f738439be415b38292c6dbdd17e532ef));
data[156] = Pairing.G1Point(uint256(0x198fbc2c6a4f1d92dcae5a77f8b1c5442dd7eb14b3630ee6c15fbf822a764cf9), uint256(0x288d72e30256bce131477531d66b4c1edb0cb3d43c1867133b5c115e2bf87e93));
data[157] = Pairing.G1Point(uint256(0x180af1e9b8466a04163f0dbeab1459134ae227659800b7dddebb39f3749b7615), uint256(0x0ddc0856f9a3437a93976001a8ffe01ac3e1e2e1b6e70a68926b77f2ae09976a));
data[158] = Pairing.G1Point(uint256(0x1a25a30f2aeff5b3e9eb3ac43786e595ba6187db5beaaccbaa656e03223fe3f7), uint256(0x0dd1ab2cdf24ccbb3547e3d777f71c99ca304687058bc6379e62d0995e89a9a1));
data[159] = Pairing.G1Point(uint256(0x04655242db6fffcf8c46bf2577e2070e22463e794c9b6baae876be7616b68abe), uint256(0x13665313d4c56db5287ad8eccd4061e9f687902c4d4d9d06aeab4d71df9fbf73));
data[160] = Pairing.G1Point(uint256(0x12b2eccc21591824154267794ceeb1f6b2db8c256b8070d9b031ec3ab37c2d79), uint256(0x091deb4a47e221b713da9b3155892f7430ca711695a3c56a267dad0c563032cd));
data[161] = Pairing.G1Point(uint256(0x1be935114e0ed6c93a61a110da4834b64d6066224efd0f305d88a6d37fa9a6a1), uint256(0x2990e7c1da97edeba712f66d374c9ad30d780eac712a4ae0ed95c54bc5b702d6));
data[162] = Pairing.G1Point(uint256(0x1c6a03433a3c86239ea13264b4c396b64fc7b9ef5ab4dbda32936220bb4406e9), uint256(0x107c53ddefe2010f2d5f7c39cad56011830401312f6db4e47ca7f8767ed152e9));
data[163] = Pairing.G1Point(uint256(0x28c97e327743964cdec3778c21fadce81eeab343734aa24e7cdcebeef4c36b1c), uint256(0x2e3ecfacf44b56f6d0dc8789a79f2646dfb129ad1d1fc79b5adf4b1d408e00a8));
data[164] = Pairing.G1Point(uint256(0x0307c5c0efa9bcb4bd57c4a6c1c6e174afaec438577996f49ca646a557245d3b), uint256(0x0a862260fabb7e52afbb294a8c505a6899b14a5e9eb5d186a8aa17a90e8c65cf));
data[165] = Pairing.G1Point(uint256(0x0c7386a40ad88784478c1a7004f6b6522dadd807a4deeda6dbe5e4a0528167d9), uint256(0x0b8f630295e964dd36a3ac35bb6f259a48d48e87204b86b963a19ede6e8cb958));
data[166] = Pairing.G1Point(uint256(0x0d8d94e0ed2445ae8a512ef9a6975a8950fc7896c668017b3a3eaa3377f6359e), uint256(0x231032f194500260f496c855c4be78399b97f0117c0ad0df6467d5f7dee92aad));
data[167] = Pairing.G1Point(uint256(0x2def3310f08bebec634ad64239876be9fb91fba1e45308c3da148d86ef4d0a32), uint256(0x140ff3235768070d5ce025a9fadbedfe30f6bcae89ba2383c981777baa8acff1));
data[168] = Pairing.G1Point(uint256(0x27e915ffa04c6c5be9a17a913f81aaf71a433e8361d0e8889fddd92b986bbecf), uint256(0x27f4befbf4352d1766580f20160d79a9b0f2814a7bb8f113294e7e30f992f097));
data[169] = Pairing.G1Point(uint256(0x1062d8ef167fc277cc56583c4cdaabfc1ec8ee4c914152e5e33e5bfc97aa91e7), uint256(0x0414a26ac904f2529e2f0d6bd8a1b84fde7c59b05edf14409e9361658ce40dd7));
data[170] = Pairing.G1Point(uint256(0x15f82a43292c44fefdbfbce06a83851d2bc88c9ab467cc6d19ab3b95ff93077f), uint256(0x1aa7c411bd4c099eb1c1ca8ce21202586a844c4ff25600fd7b53b404fcf5d21c));
data[171] = Pairing.G1Point(uint256(0x18c66688a29e9668418580da355e65c9bf36c7f07cde34d0737e1b6d5c565302), uint256(0x0c67fae43d13e18e6f2801c2243b626d32effda5740d466c1f4458b527d73e90));
data[172] = Pairing.G1Point(uint256(0x15f2b47e2e2e05f73e8d78dea69f8f8e83df11adbe586d8f437ab4c82fb2ce00), uint256(0x283c5f16f58e1cda29bdba9f30ce2aecba4c69920fb91957505867796f4068b7));
data[173] = Pairing.G1Point(uint256(0x0d9106f4b9d30c2dbce4e8ab36db3591c6768668c26fc4c45cfb4976365459c5), uint256(0x13ed56188aff020e045fe25db019e4396975998682ae77ef76feb2d7208f825f));
data[174] = Pairing.G1Point(uint256(0x27c226219f62f8476a3a38e54acdf95f8fe362c5abd5852f3af84c5234522aaf), uint256(0x1b62146af6a9b6bad975c908f2f4d85a450d4a963f8875c4c7734d696687bdaa));
data[175] = Pairing.G1Point(uint256(0x2849d7fb78eda0cfc78a688181aa4bf77ad539f0354df605933725968b84090e), uint256(0x1cd9fa2e249a3964af4f3b0e58db063965731569cfad109703523548c8d2ab96));
data[176] = Pairing.G1Point(uint256(0x00b98559bbc4b886154c17dc240f1813c8cfd96381cd4e4e4f2b617acda6da78), uint256(0x216aa68a98f80d4fa0b4890445d11b9acd1c64e73583599d4152f77509dce43a));
data[177] = Pairing.G1Point(uint256(0x1d03d89b883fd423de2b3cd7a9c3b2b01c7662340086053b7ea28e794eedf73c), uint256(0x054f1e16f0ea99ddc594d09b223e59ccd8e57cbbd154bbe096c73712defd6113));
data[178] = Pairing.G1Point(uint256(0x13aa925cbf3ed307e8245cc1dda680ebed490308ece590e76eb7abcdb33bffc2), uint256(0x207933f374c6c4abbfd133d948922e850ae9800ad73a18a5bed3fb7dd1ef76ec));
data[179] = Pairing.G1Point(uint256(0x2dfd4b62e5499b4e7d8cbf660897f1167a1ddba5eb59bb2901047a777e50e8c9), uint256(0x1ab6d6fe75f51662ec4a2c0ac62110901784f15c70658b5b1ee5c4826091e898));
data[180] = Pairing.G1Point(uint256(0x0f805152d99801765b06a6fdadd2d35ba0321e8c5f26b3bb7eb2218f37e90144), uint256(0x1fe2a868e074fb77b5e4ee137f0c52dca8b62c3da6aed37e4e9180e44c434c42));
data[181] = Pairing.G1Point(uint256(0x02b31194027648ae15909960bfa5fb81a7f70c16daed1161bff1b8e405126776), uint256(0x0efbd0a2f5fde8c4c3b8e8690d63460aecaf9134a550c1615daae2237d0f45ee));
data[182] = Pairing.G1Point(uint256(0x089a17976865e959c7ded1ddbec853b5710c1b56015ca7117897a6acab983864), uint256(0x25626735eb7d0b5580e5a1e148991576d46be49f4cefacbd85d7bee91647e15c));
data[183] = Pairing.G1Point(uint256(0x2458403e5b66f933dcaa718c5f02face51e30e2d7a49fe7eab0efe94a98d6162), uint256(0x2e9203051ec245f111aab612465bd3e8d2c1e36542940ca87ea8837f4f64d95b));
data[184] = Pairing.G1Point(uint256(0x14e1d5fa89e3bf22054c1b9461489ece81b8a9f8884cee166562e9b34e34ffdd), uint256(0x0424ebacbca82415a2c1f7191847a2982290803a5b2bbcf1b4139e939c5f4d10));
data[185] = Pairing.G1Point(uint256(0x2c25659022bf7602515c81a6f71c5f5aafafa45cc03cc29d810f2afa6f6f7357), uint256(0x105f777559d57c4b38dfb2e5931e9817dd50e52c3127c10af588224306c70727));
data[186] = Pairing.G1Point(uint256(0x13e5f7456f4657976345ddd34ad7a3ee5e360e7b22edf5aad98c3a5ea06212d1), uint256(0x00c1fefa914a7b07ee34b63508a69f87ea37e36d549ec1ece04d727778393a14));
data[187] = Pairing.G1Point(uint256(0x21421119748f79f5bad7d1875c7f2a0e5487ff3c2e33efb1267f266d26b4c903), uint256(0x2d7e0084d4d816e9ca7f042f455e7424f4e0cc32d5774f310b35d70bf10c2973));
data[188] = Pairing.G1Point(uint256(0x2ece25575534398fa570f5b7564cff4d44a6c10e966f237879b93fa0bc7e6a44), uint256(0x171de31379c2a32b039f6dd88c1a57b99e0092baccfe9170c0fb9c87bb3ed89b));
data[189] = Pairing.G1Point(uint256(0x23c71208256a112dc6e515f2c52479914b74521b9ffbb53d54bca21a52e8cbe3), uint256(0x0eb24c1be1dded9883be1f0aeb95d9e18b80584bb776a92c4d56bface6d21e61));
data[190] = Pairing.G1Point(uint256(0x256e3eec88930b123372ecb5a0396ed77e2a7578a294f3e0d0b0083a3b0ebc1f), uint256(0x14d6ca8d79fbfaf7cceb172f619557afce7bc20abde6725d03ef4f5284e21ea9));
data[191] = Pairing.G1Point(uint256(0x204fe63ea5f8b1096baf6d97e7d13256a54db74ebc836764e9abe8cc5fc7201c), uint256(0x0af7634c185795be51b264d31bcf1e26f15a1abc6f26fd9841446eee38f18de3));
data[192] = Pairing.G1Point(uint256(0x044a02c4c3d725f981806b845be1de894763af4318c24e0aad0580afa7c7ed17), uint256(0x106e9e5418e3524ac109b1e86d37560efba483bc10dca0e856a13568d5dc005c));
data[193] = Pairing.G1Point(uint256(0x2d9633fd1be5806f47947d09354d7172a2b1140c0e046fd66e97d5a8d21b469d), uint256(0x0fa77cb0a186798bd85a19a54a23722969d362b520d12011ccab8d2342921c12));
data[194] = Pairing.G1Point(uint256(0x28adc1a764f5da951c10fd95b24a335562f19cd6323cda8c746d0639754b170f), uint256(0x233ebfe23c11abc1f7ed28a4217d363ee5408b4e2e889d6795d862c2821bc6e0));
data[195] = Pairing.G1Point(uint256(0x1391f4722f7117aafd51ce09adff34edfccd6efae4cbdd494416b38b23e05de7), uint256(0x116783944b8880a95803c012013912bed3754beac143d818768af085f6adb0f7));
data[196] = Pairing.G1Point(uint256(0x106a4cf4a085b013188dcda3ae9a2a2b1215fe262f9a5c1659a88a7878b8f5db), uint256(0x01379f950b76a7532081818cf35b718bf2d40eb8ca1eacf629bb809d12a60fe4));
data[197] = Pairing.G1Point(uint256(0x0ab05a9850ba458c22f5c30ccaf5b7f86432416b50227e21ef444d5044652cab), uint256(0x22c1c57266b3e635c8080534762df64cfc598e843432f04993c24fba77d8f5a4));
data[198] = Pairing.G1Point(uint256(0x26e087cea3736f18784664b9c7d1997d826054ef34a15334cf78eb48a257d15a), uint256(0x29b015f404cea77e2764ff5bc6142f0ccf9049a63833162bd96115deee5ab376));
data[199] = Pairing.G1Point(uint256(0x1377ff59982368d6c8bafb250a9f31dba65b3081d82d7e02de3de5f95b3b30b3), uint256(0x248858a22feb4fd10ade0cd43e9f4bf90f5e73d87e849d7e526ecf2a6b40fd8e));
        
        Pairing.G1Point memory vk_x1 = Pairing.G1Point(m1, n1);
        for (uint i = 0; i < iinput.length; i++) {
            vk_x1 = Pairing.addition(vk_x1, Pairing.scalar_mul(data[i], uint(iinput[i])));
        }
        return (vk_x1.X,vk_x1.Y);
    }
}

pragma solidity ^0.6.1;
library GetVK800 {
    using Pairing for *;
    function getvk(uint m1, uint n1, uint32[] memory iinput) public view returns (uint x1, uint  y1) {
        Pairing.G1Point[] memory data = new Pairing.G1Point[](200);
        data[0] = Pairing.G1Point(uint256(0x0f9f8ddc4e5263f764e29913e2308b64b64aaf92adafb2190bb63510232c5787), uint256(0x0909c056b144e149b77f3f0a7ee7a8aa4d5de53b1731d1b7b00d9897fd95e761));
data[1] = Pairing.G1Point(uint256(0x2b83737280ab441b14fe61e43867a093a493da29f892ee3c2eda372cf1d19442), uint256(0x298f0874ee89807a5eeeadf3ea5af141922dcbe62c005f5ddfbb77f79b8cc05c));
data[2] = Pairing.G1Point(uint256(0x03fc61f7fe1523a9c988a610b0c78c87820c8861eac6177d856b473b4a788849), uint256(0x00b2844a96e1606282aa37f0899341f551937a443f216e4309d3cbbb36a59702));
data[3] = Pairing.G1Point(uint256(0x06c81007f9ee2e1a969b5997c6c1e4024afb2993da2b24c794497d0017ca3434), uint256(0x1e6e52e3cfb974697aced2fe295555442d5e7cec92e8001948544b6f3c80b6b0));
data[4] = Pairing.G1Point(uint256(0x0e53f7500b0bb587b054bc55e984aaac9233fb33cef02051ff4c74328492d98e), uint256(0x060d0b4d4a15dfa27a8ffa3d384258d4d2c1e31fbd71f6c3cefaf7ad7b0e86b0));
data[5] = Pairing.G1Point(uint256(0x13c0c42a8b11b97265f948f12fcbb2683303789cf8c9a904fdccbfe7bdfc682c), uint256(0x0a45069c188941667cbc3c99a7505a1df426826386320b02d6ebba2184650c79));
data[6] = Pairing.G1Point(uint256(0x2b508251fe3abbb03d29b72284ffea274ef86a80c832239d2f09a61d6e97ea6e), uint256(0x03eef2568b756348d3c5808b10c5784ffe3a662fddaf7ee22e5978430ea52177));
data[7] = Pairing.G1Point(uint256(0x07ac9675cef96f2577b9db653d9575617eba2f233aa7c314c3cf13515153c632), uint256(0x04b3a9c7a62ef5d6c41ef6d1ab864ca179c9d5603cb10d9cb3f5c4e9003bc6e6));
data[8] = Pairing.G1Point(uint256(0x120b5977330840617da57241ecb1e97344e8420cda407b73aed2ba4d79f8f78c), uint256(0x189f9cfa5fd335d9774bd345d17434579112ac19c9f40db204fe48c9559470a3));
data[9] = Pairing.G1Point(uint256(0x302cec85395c368d52a8468225f7ae19a1d0a9848decb29431192a9c3c91c900), uint256(0x2a20b0cf6b6c3a7c07bf0f004edeb96e072c4cb23ed60f76400c229b122cc804));
data[10] = Pairing.G1Point(uint256(0x09a82b4065087d2b508eb9266918bba518e3f263560b213a4fe337f32aba7230), uint256(0x2f46c423f30a9b0c0a8c33111145d8053d8b62cf4722baba1e284567dd5af671));
data[11] = Pairing.G1Point(uint256(0x07b3f44a0cca9586b7f0d8affd52151c2b79954ce75bda07daaa9c67dbb8907f), uint256(0x1476a8c48a0181d29827ad150bae6630be300169a2b8838c5c29a929d24dd6e7));
data[12] = Pairing.G1Point(uint256(0x00b739e21b3b5282ff8d68587e2535c68ecc241bdb0ed0d0856eaefdca44378d), uint256(0x2f88098c459eb5b85ee63528449cd5c272a458e1a7cd8c3bfdda22d747c6fb62));
data[13] = Pairing.G1Point(uint256(0x024adf88e1fa2b77edeb582f5411505842de774139ac615f305ffe6cddb59f57), uint256(0x0ab8dee6f6463c0d697c3d6fcb6f1dc208b16594abc1bdec85593dcdbc1c309a));
data[14] = Pairing.G1Point(uint256(0x18ddb7ea70f47217290f3e37c853a8225f7ad7b069997a592630e09d2bc30337), uint256(0x013bfb4a1c08e576f0ceac8c54dc5cab25d5be56fe517be491026ea121379908));
data[15] = Pairing.G1Point(uint256(0x133a32d226bd9f24708d94efff06ed7e1079c023124f61ecb11cf3d5162549de), uint256(0x19e47013d1359e90be20c19543850e87cbb8f0e69369d7db31f6a2d2b18296a7));
data[16] = Pairing.G1Point(uint256(0x2d08893017720cda03aa42244ddb738edb3a6c26ba7e58aee177980d04ce121a), uint256(0x2145d8fd13baada3fd6097c722efdbf861f6073099e1b5b1c211ed80d5475686));
data[17] = Pairing.G1Point(uint256(0x11134b0cdabfea12754368700257305ba871bb00ccc507adb87eb540fb216a39), uint256(0x14b96f371e75d76de7f0b076ef10cece13d1846c4bb0ae507443b48ca69b52e7));
data[18] = Pairing.G1Point(uint256(0x2803456045532554c884868aa4295407ed5c77d8b720fbc7a6d7a800407b8503), uint256(0x130723a936069794756ab8d5ffc74d68274fdcd2e3fe9c099bb6885258d96ab2));
data[19] = Pairing.G1Point(uint256(0x0b8b80cc78bc9a7b0cde7984804f9fae377cdb1246236ea395049b6048f249f4), uint256(0x13231d0867eab741340d6e5b663573e964e75836699391a1b004b3bbda1ec655));
data[20] = Pairing.G1Point(uint256(0x3019935e43b1bbe64c26480d3f011deff6104c32387e7f677d6fc2cf58648fd1), uint256(0x2d9860ef8617d36541c7cff40118920eb8b5fdc70ba8cdb0c450387bde21e59d));
data[21] = Pairing.G1Point(uint256(0x03d860eee4aaa37b8261cd71cbe44970697d5ff08e7caf0b44e3987729ab17ad), uint256(0x29a8d4f240b7a3f2da7889426def9f18607d4bf8e01a5aee9aba8d5a1264f07f));
data[22] = Pairing.G1Point(uint256(0x0ce9476ff958616fa1705c3db1d72497530dbd9fd0cf3d8359146075e7b84a3a), uint256(0x2b922b7498677529c060cb6fbea77184e8002532d2e3ed832f16e78c170306ed));
data[23] = Pairing.G1Point(uint256(0x228978a8c1774579baeae68de7089bbc1190db485f4e15c82f861fe6171954ad), uint256(0x201bfe456ff0b06d05fd6c1fa5d64fa9e841837a56dc4e583173735541e1d3b1));
data[24] = Pairing.G1Point(uint256(0x004a72a76fbeb7fce0697a61ae354673732881740b8fb9884bddaf680becd79a), uint256(0x199bb8730d0019ee0dbc0386b3199d3747c3bba2dc229ea02746301310d6a593));
data[25] = Pairing.G1Point(uint256(0x1943505e1b54ced96344831a0e0b66b042306848135a3be701e97050bd5eba64), uint256(0x0b96f9c7fff445132683649155cf1e70df168e2d5805896410dd0335d2b8ec70));
data[26] = Pairing.G1Point(uint256(0x11d7ac17f86b60ea0c8516d7fe355ce9498da1073651f892bddec23c788ba5e9), uint256(0x092b36de08184007465c97388df1691eef64ccfd14ef3ff98e256481afd7cc86));
data[27] = Pairing.G1Point(uint256(0x1202380f079807039229c15fae144b37fcc4d909b809044e1909d326bed73b25), uint256(0x0cccb5dfd8d4456bf0bfa198fdc2f6f4cdc4ff843b14c9aedfb2cb8782bab81c));
data[28] = Pairing.G1Point(uint256(0x22a4b5959bbddd6686e9aae778bb170928b861efe131ba1f713019f40ae1191e), uint256(0x0b1e18c41d0e51796f088c0c42ede4bd71035bf422a7307ba52d59098275e8f7));
data[29] = Pairing.G1Point(uint256(0x0995e6be190e25b2e16b87523bf066d823a3703e5aecbddae5fc8c5d977682bf), uint256(0x24087a695a3586288729d8ef3984a524cd8b559e506abd365c79fcc474d05692));
data[30] = Pairing.G1Point(uint256(0x214c71daca7f2307f8b7b0d388a092d44ff7ced47971ea744cd987e1cf0d7683), uint256(0x131bfaf3eaca2e2e00afde6dd21083048a01e5dc36937f323033581ed18b68ba));
data[31] = Pairing.G1Point(uint256(0x0edb0288aa563ee34c30feadea2233172b7071725c1c4f96225037c0395f2dde), uint256(0x1574becb386fdb35150ca619dffb27d8118669e2563d0e86e24b65bb727b6e7b));
data[32] = Pairing.G1Point(uint256(0x14dc6f13202c478a26460b9e1bd774314029df4ae5ac4b7707fa2b078ed271cc), uint256(0x2502916ed0d3c9d0a995d74464a05878b2dcb2ac2e79631c6834f0261582815e));
data[33] = Pairing.G1Point(uint256(0x175db53d0dd9140a1a48fbdc970578653a6f833bda1a29ba03eca0a976430e71), uint256(0x15ba68859f03290dd23ec851c7cbf277ec920be5817879079d658b295eafec0e));
data[34] = Pairing.G1Point(uint256(0x26a8070a12b7f4246ea26b70c606a192e3a72a63ce282d361fdb62cee9739c6f), uint256(0x0cc3b0fcfd3af133b8757b992a563f67adb270f80bb48df855af60dad692d5b1));
data[35] = Pairing.G1Point(uint256(0x279bef779bb82e940d74f7b33a26a320429235ed5f368a10a147bdb7628be1c2), uint256(0x04194785f65466add078ffe174dbc52f043fa57b88fb7073cb9c1bc2069dfb6b));
data[36] = Pairing.G1Point(uint256(0x27a9a987e5c2e3c7dde1615562fb7b8bdfe6fd5ecd679f309d8b5cf9397c50aa), uint256(0x0f3f41f8f116dbc6028593e4d21ae624ddcad12f7310d946545e29da83ebd134));
data[37] = Pairing.G1Point(uint256(0x16da564e99856eeed3e1cc664191dbf4050589418d6256b6535ffcacb2bb103f), uint256(0x21ebba56e3ad10666cb4a3db1bfae6529396711bc326984ad869977e32475452));
data[38] = Pairing.G1Point(uint256(0x26ab30524b63854eff17232a4ad3beb6d655d9a52f715599ada42346ea4835ef), uint256(0x044ee095226a36745e6936d6023d32ac9ac64f1581e4763aabfc3d7f9d59870f));
data[39] = Pairing.G1Point(uint256(0x2e3402f195b980b919f68038a1ec081d1e803bacad6eb17cbc24ea768c52b674), uint256(0x2db72c37a27d845e492dd78ec53ad859908deed25dcc4c7bccdf337e123e775b));
data[40] = Pairing.G1Point(uint256(0x1a3f32512abaf1d2fe9e65e8f7d07cf75cbc4271001c905c6ad3bd4b4e485222), uint256(0x26803e01a89ca8ed95d1531e496aa5ae8fd1769ad60f79c24d5894f6d71d7751));
data[41] = Pairing.G1Point(uint256(0x0ed664c589200f597ab29bc3eab97c1159009db20907689384bf1c3f7e4bc68d), uint256(0x16e88b871118e8769038b6477cd94589bc4b152e4dbc45a9550986b8b4cb2331));
data[42] = Pairing.G1Point(uint256(0x09cdbc6ca7e235db4d887827fb893ef0d09e852773aeba95d11a045906f0c28d), uint256(0x1521815b386fd8d9fa9f858a74131a8e4586cbb89289ca8e9e0ec67869d51b9f));
data[43] = Pairing.G1Point(uint256(0x1dd8a8f0a5d5b8adf6f56cbd8869dd5070d2a636e2ee54a9a4041400490b3770), uint256(0x2c63ae635b1050fbed2644c3d3d4da8f2903db11ebf87a445cc44dd220c5f624));
data[44] = Pairing.G1Point(uint256(0x27d38aa727ecae6534f9045211b2f7a38512796534d3287a981a8425362e56b0), uint256(0x1cd9e95f0ad96f0e6e009de952c5a3dc6cb31a75447201004f69d409703cce77));
data[45] = Pairing.G1Point(uint256(0x1119f2de748001b1461ca90740d339c1f247e3ddd98407a25dc526c073455b08), uint256(0x10059cf36cebd869b93bd3976add767bb478a4037603bf00777a88df8bd91cbc));
data[46] = Pairing.G1Point(uint256(0x173f68dcded4ceab77100a11801c60a46a12d886cb24a41bd45afb985c5245c6), uint256(0x2b06e192bdeb448f3f86751a8e38a1793b31e3b4f166ee36c999c62d8812d359));
data[47] = Pairing.G1Point(uint256(0x2fa13ac3e1f378ce8ac58bee4c8b283b4b79abaf805dd76bf4ac876bde318b32), uint256(0x0a520b42f9d6377a680e566871a724f0715a74684fbeb8bc4a1f45d5e3228207));
data[48] = Pairing.G1Point(uint256(0x0b9ffd8295d5f0789b0014b66a843ca717e62a8f8e9a3c2313c8eecdb2e4ff2b), uint256(0x024ddd55dc632eb39a49cfbee64a1e534246e4788bd302102684726442a362e9));
data[49] = Pairing.G1Point(uint256(0x0be62496fa9279b7a1f915f380b25ad6b32659f0007efdf6edd847df815ec547), uint256(0x1601d2d4942a72d124cc0948d8feb94342b003fcd1f60ecbac50ad6f90dc6e6e));
data[50] = Pairing.G1Point(uint256(0x1206d4de3b704b8f048006896c4792350f877459121da18044c5a56dcf3ecd53), uint256(0x11cc6fe9b17d3434edbf6e33f7f630ccdbbeb620224b897948d65eca2701c427));
data[51] = Pairing.G1Point(uint256(0x15569737a89d983a15768741c26124e00940c05aab037d8e33f0f7cfd3511445), uint256(0x11d419298b0e296bfdd63418ef2d50e5da053cbbc6a5639f17dd228d53403b0a));
data[52] = Pairing.G1Point(uint256(0x0ec876a6049ca1ccc8ee5b001ac796661e0c493f490fde5399ab64f46db28c6b), uint256(0x0383582ab0a7a78110b8eacfb333ddbdbea8a863ccf9e13e327c5dbd4475bf32));
data[53] = Pairing.G1Point(uint256(0x239e4f6729aa68459cc37523397cbef17bdf1e0e8dfe8ba019a969f2ca61db03), uint256(0x29e5700b78f18605ba92f0eac3a6cfd423e58c8d23bb353d288f135a4cdef568));
data[54] = Pairing.G1Point(uint256(0x0c8f3940c3eb48d6ff7e3cb56348d91f09a245bdac48f6e33c67b3c3ca8a54d1), uint256(0x2823693bcc3071312fadd90cd79cc11a0c703d1702dadde451cce2c4cba06d43));
data[55] = Pairing.G1Point(uint256(0x18f2d78ab55e02497030d05f2f3dc17e8fc3ecfff359f5066ad60d8cdec32e53), uint256(0x14f586a890b1276467ff4d2b01207cee6a789a4c6f5c26f16e4826f21f720c67));
data[56] = Pairing.G1Point(uint256(0x0ea1c0562f35a02d0f642094cd5033cf31b8d84d790dec223c9b61715418a3c2), uint256(0x2fde983a7cc22e066769533f0599b972c4feefd5c1675a6acce2218d5365d794));
data[57] = Pairing.G1Point(uint256(0x03af1a60bce0974c566dc234be8dd9d93462d2d8d791b8d0358b06736a34630a), uint256(0x2319fa33b29b2b4579633904d687d6d71d655da02da434c29a63371067efe867));
data[58] = Pairing.G1Point(uint256(0x17ddc7865267be3ba42ec7f38ed78f78a763439e04f0b301a0a958bf5b8102d4), uint256(0x2288ad1cdfb8c4bdd77805b9281c870416e0bf06a500d30366e309af31634a75));
data[59] = Pairing.G1Point(uint256(0x053d8208be916921dd7f1165dfc429fc526aaf3525672f50045de63396a23c3c), uint256(0x23b038021f36b41e1edecea6c0b5521b778d941671384ee9cee400ca0f423a8b));
data[60] = Pairing.G1Point(uint256(0x28cdc7c573fc49ef2b3aeb142e35db045432be9e35b19dec524af144bb5ba104), uint256(0x112acf195261cd543f5b89ac2122498e9f938c9d8e28e03473bd0ca4e431d7a2));
data[61] = Pairing.G1Point(uint256(0x27349800f4348472e4c66f22c2ed96a125bb4dd63db67c0cf51214ad7fad3c93), uint256(0x1224bd5effb1adced87db1d9e8dff5a448678c1cfb37e1716bf582687621c049));
data[62] = Pairing.G1Point(uint256(0x10b062b77b8d44d2951a0be03b5add348f9c4758616fb36fe752245f941964c3), uint256(0x06816dc73d74c001024542f77aaf2c8251f7b7512da0620f16bfa6dbdbd2d6b4));
data[63] = Pairing.G1Point(uint256(0x1be71c84de81e52d5f1c67202624b8313a6fd0eafa8c30763d4d083131fbc0bc), uint256(0x08381a577fa2b0204b0f70b243c416c678cc2c33735c163eafa0a09991905fd2));
data[64] = Pairing.G1Point(uint256(0x2f42bdc5add96125341fdec6c2cc8a84960546d916329e4b714798907a0e0407), uint256(0x07e66fbc526fa55926ba6c2a889435818c05acf22666c27c0c4474a48a821c9d));
data[65] = Pairing.G1Point(uint256(0x18565fec65b2ee0a930c7ebfb99e9b82e676466166db79028fd6fa69aa48055a), uint256(0x1b328541e3e9f7d1d711c7cd8b341237a0c9e82817fee2128545d2e73d489250));
data[66] = Pairing.G1Point(uint256(0x1718a5a0f278f5ab48429ff9e7cab55bc6a445af1fe8cd84b498775581762373), uint256(0x1f98920b1c46f2f3286cafdde967fda1231ce775bb63c35e9c62cb7b888606db));
data[67] = Pairing.G1Point(uint256(0x2dfefd936bae088cdf1ea47a2da0fcafc27a6b652558a70e08859ba329cbea4d), uint256(0x089511c763b9ca2ea523f970e15702c44cdece0189d030688322bb60a9485400));
data[68] = Pairing.G1Point(uint256(0x26685cde1d3118306ab0edecd5d015ae93a0628644df305b7cd5f2128a782e74), uint256(0x03a8a636a2396156ad1110d008dabd08726663fda431191d1b3d8e925e02bb6b));
data[69] = Pairing.G1Point(uint256(0x1de4e292397aeb3ab015684e57956a02e55102f2491de67755189a362ee0375b), uint256(0x0802821741db5a1cbe87febc59cfa56e1058eba80fe8e2bed94ea90e1156f037));
data[70] = Pairing.G1Point(uint256(0x0973d2e72bc5e54d1ae544a41db4059dddd3aa690c6da516e1b35c3afa0db95b), uint256(0x2f8180e0c900f2fc41280812ea11361517664d21bda78ee10568945d99c56f52));
data[71] = Pairing.G1Point(uint256(0x00c5b6a4519c35f974ec6539001b8b2234745523294bbc6e44e33aa47a98cda2), uint256(0x0a5f612bda425bc3bf527e70b2f1d0157d28dcc4c6627512506f3f376352c467));
data[72] = Pairing.G1Point(uint256(0x1d6392b18cdf8fb6afc78efb56fd1e06b97d73199604c171be911c0a1394e7d8), uint256(0x2637d8124380c68b635e684d71dc7a3c43edf666e079d92d39c3d533cfe1ba51));
data[73] = Pairing.G1Point(uint256(0x1241fffcf07c96bef05f48fe5d703ebd764cbc0bd76166a15e6cc8c07ca289c9), uint256(0x0d34acbbce4ada46417e7ad92a78e48729fd2ebbaf1e70b43ee70e1342132250));
data[74] = Pairing.G1Point(uint256(0x161e1a72b4fc845bff86594e8aa8a089af3a5d727578e6a0bd2888526be76407), uint256(0x292c12f736a1910fd61517b4d2f5c9ec7f5f1aae1a29e58b68f3b0d0bc8e7a12));
data[75] = Pairing.G1Point(uint256(0x1e4adf989a1f6755b88c91897b0bcb5e89017f84afdea39b6c4dff2eb7edd015), uint256(0x03458d7e2c8906f1547a4a94d3b3b22c9fbbcd7c0d345ed6dc4c50fabe768694));
data[76] = Pairing.G1Point(uint256(0x089b474b75b794a2850a65521ac92543014553072d372417a02eea24b18385f6), uint256(0x05d3170ac01dd2d3a9b7dbe03cec23abbd04c86fe0a792a24dd2fcb1bafb8bde));
data[77] = Pairing.G1Point(uint256(0x2a4bf308993300f2707dee92986217d0e400e87804a4a8f4bc48c4f77be4f29d), uint256(0x0d8ebcc939fc06fe6745618e4c2c331fe1de0a92e26a6610b4c8547366f815e1));
data[78] = Pairing.G1Point(uint256(0x1fe6c2509e715ac2a31c967be4fe51e590ff9697a249cc5b06fdbea6beb99e52), uint256(0x2b9ab71d8a521e644715f76ad83a29d71a61110f4b5f86250d43275d2e6c47cf));
data[79] = Pairing.G1Point(uint256(0x1ecf10ef2a8dba2351b9d1f146b87eddb4add40e04b459f65d6cb3fe4d6c0db0), uint256(0x1c7d2109f298fa071641121cdef9b68cb81fa6abd7b70523cf584faad33df950));
data[80] = Pairing.G1Point(uint256(0x112139bded878ccb78daa6e22683600cd414343c8fa69a276d5163525ffa0181), uint256(0x2d507f80b3f8a14f574393315aaaa4ded47537e301f5696a14e4306b279c3fe3));
data[81] = Pairing.G1Point(uint256(0x1d5abc31f5d19ded331da20343b0d8b7df99c0c23bbe20999c33647a7d0d30d3), uint256(0x0f78efe89e1d05b9878d36ef02cc28168379f4818d4fd69ea5bfb99324143487));
data[82] = Pairing.G1Point(uint256(0x24326611a28e811a02ea7c53e132629f7d86adbbd7d49764d818f85ece504352), uint256(0x24006597a867e157576b0885d0db24d8889df7d3e8ea53bac7eab14962914a09));
data[83] = Pairing.G1Point(uint256(0x2f902a6907ee61cd09d8fb26bf6efa817b91aaf0c87ea0253ddc9d7a43e427c6), uint256(0x19b3a8910eaa3b4996fb91ed0f3573b4e274416ab48fd9947d436efe2cb788f0));
data[84] = Pairing.G1Point(uint256(0x01759608ecded9ca51d1ae08b71d960d45957e377dd1afb215611382a1809512), uint256(0x0fb63b27a30d276f1b4ad9544847b4f407820dd34d20d948f6f53dd2f5079fae));
data[85] = Pairing.G1Point(uint256(0x24546ffc7150943869f430e0ca31fb9fa03396bfef8312f0fcd02f3a232cd147), uint256(0x2d36255d09e4c4b3066a24d072c446c76dcbd4785bb349587a9a9064e46271ed));
data[86] = Pairing.G1Point(uint256(0x27b9013f20c0ebec62014bc11db778f0a3b405e1c1888a0b4c5ed2bfa164e90a), uint256(0x2165852e0b170a8c354e98e69997485401a32fc33fbaa0ae291cc3bc02b2f96c));
data[87] = Pairing.G1Point(uint256(0x2a4b30613faa490f5e0d5de24196ea2f9ef7f7d11bc3f8e88ba4c2b60042c34c), uint256(0x1f3161739df145dbb726a9d4aadbfd95cecc6d12e2509c75d5780e855dc829a2));
data[88] = Pairing.G1Point(uint256(0x0c01b59d537d5b0e8f53c8e793b9d9f05920e7cd50333f10e1e546a1211dd174), uint256(0x276cc89ffc77de5fa538ea6d71c326b360bf87b28c9a634dd233514a175e93bc));
data[89] = Pairing.G1Point(uint256(0x20c23c69dacb5752c9854aa75b4b78fadc3efa44e918f0b5d3b14f04e8fb751a), uint256(0x12db526b4528adb086f86cd710f71c433a0cd5ea61bf9004c699c39d54fcde6f));
data[90] = Pairing.G1Point(uint256(0x0cb85ec54a1035a567fb1680c66127aaebccd3861f96ab3616bb2ecf646d3d98), uint256(0x07e9203991af020baf3d128ba7cf77106b64766a2810182aead24bd79234ef2b));
data[91] = Pairing.G1Point(uint256(0x12c3e1379ba342660cdca6a9be9dc8809152a608873769185a16b1f02456c3b2), uint256(0x0efc45e6b928d608e616a70b5a930ccef08cc5f6acbdb0031ecbdfab52a74ff5));
data[92] = Pairing.G1Point(uint256(0x1c10d72963e0ac04e5abef1c228b3f1ad2550318ff9381643deee58d4e464220), uint256(0x06756132351cce8374ce0fa0991b6d5f5c29f9934a1d23f53f691050e852bbf4));
data[93] = Pairing.G1Point(uint256(0x1bdceec09bab915f3c6ff539cbcc084b32817a9954cbd259f1456e3ae46fb7b2), uint256(0x11aa4e3bdeedbc6c76079e66bcdff3916b15e05bfa955357f62604354b12a70d));
data[94] = Pairing.G1Point(uint256(0x25040b6c1609cb3beaa7f974794393fe1b0e6bd6d0977267ea8306f203267861), uint256(0x02bdc38ad693a6630b3ee7423733d256329991849d0e9ab99049afddff3d8fdc));
data[95] = Pairing.G1Point(uint256(0x042bbad7146db06b2902ceabe5d562a30888086f45f680711e72be9414842540), uint256(0x041ac8db1ac031548102e7f74a41fb363467177002c2e7ac6846338f0f886108));
data[96] = Pairing.G1Point(uint256(0x0ee8a8625e8127827ab2533622fa1f9bd4cb7f81d3822c5fa639a83afeb8dd97), uint256(0x08b10d8a6a0e91b9441a48966e7dfdf54a56f2348e69b83e1b54b81eaaea8672));
data[97] = Pairing.G1Point(uint256(0x24f2d44d6e5dd0ffd929fa8a06b36a8133e4702083f8bf12e92e44f9e35aa555), uint256(0x2e45cfcdd4b6b19f1ac13c57362548e2b2b88795bf749886673a8f77881e2a5c));
data[98] = Pairing.G1Point(uint256(0x2e71c0932f79731475ac5168f682ce8ef3d7311016a745db3d71677767c58b36), uint256(0x2bf6febcdb8f33d0f3f915a341d7a162b2e0c7c35c46806552add61954c9dde6));
data[99] = Pairing.G1Point(uint256(0x010692e67143f3730886570318111bb18d94f2dace31ecc6731ea0ebd9bf7cc8), uint256(0x1c91e4b9b0481255296710a6519f9cea41726383e570feb2586f75a687191ff3));
data[100] = Pairing.G1Point(uint256(0x2c6bdb0f29fe62f16041cd953ad8363040d2c4886f6d0ac2880c765d06838f15), uint256(0x2c3cb04396ac064e421a7255b642fff7ee1858c084ab13c2280d9685b48156d9));
data[101] = Pairing.G1Point(uint256(0x2f4ea1b779b5f162f7a1fe00dc5ad8812d64cb0d4e39913672fb72d0a8e93136), uint256(0x08dac55f626c28780da43611b2f756594d90828a138c2b34e95c47e45aaf1682));
data[102] = Pairing.G1Point(uint256(0x0aa4bf31be824ef99ad37de2c5b81f5d1e9728e63ad10c859421ce261edba287), uint256(0x294d81ec766b9622c4b28d6017d20a541bc8f0a542ca81f631979b97980d089a));
data[103] = Pairing.G1Point(uint256(0x2959a0cf88c5bc0dc6114d5b0bfa8852121b09845fd7074dec975372b622631e), uint256(0x028150405baae2b78ba6385300afb0c8fbfec98f539063666ed0b95fa9d2a9a8));
data[104] = Pairing.G1Point(uint256(0x2124c66e679fdca6da9b3fd642f7d3578e634d3b4fa92bd0acd85f9051adb79f), uint256(0x02c93f4b8833981084616d6f7f25037b7beaeb9766bc58a374203c6f3b3bcaee));
data[105] = Pairing.G1Point(uint256(0x02a2b0420807180e38b591d1b18849376a6599c8abc6940936def880fd91f22b), uint256(0x1998d058f3a1518473f4f7b0acda85b4007edb51f440a244d4803e06ceec3ff2));
data[106] = Pairing.G1Point(uint256(0x2516bf53e12076abe800ba6da85fa78620bb455f40ccb9a18449410a7c45737f), uint256(0x0af8028def94c46f6fd6172f04342b3123d827e6c101e8b193ebb499438d1204));
data[107] = Pairing.G1Point(uint256(0x12b8c3af19a2b287c4f1b4de5f6d3c064a8fec7bfa41d35a454ee3cf0e3869fe), uint256(0x1ad5d2ecf8c87f718e0ffe641ad7542bb64f237c59684c665ea973af0c3d1a53));
data[108] = Pairing.G1Point(uint256(0x01f706e2e6b135ff72f9fe144ce5bb4d343d544793dc3d3d2cafdfdb0edfdb80), uint256(0x080c01014811bed2fd8682cf25967566af9bc410e4f2b983f0cfecc25d6d0de2));
data[109] = Pairing.G1Point(uint256(0x0599dc870208a84f865dc19753a71dc7393497e05fb848dc0b560ac6e3df122f), uint256(0x304d2150f692375abee6889d9c4f7ea0e6ee82282f88401f8b28d1e870bc19d0));
data[110] = Pairing.G1Point(uint256(0x2227934d2f1ea575f92f073972005eea9b0541e0733382c0c8b6f0605ebe29c7), uint256(0x137a76e0f3ab7802bdd2bfab9cf9c91779c3b5400dbf8449100bbf64cdb33962));
data[111] = Pairing.G1Point(uint256(0x11f69df6ac1b466d1cb03d887cae193c53b8348bcb88938feb5a2efd687a4602), uint256(0x130e3d32fd38cf9b66f910578aca22d040ae881db857b018fef9937ddd0a78ac));
data[112] = Pairing.G1Point(uint256(0x21f06c3aec460d2035d77e95bef0af509feb5def3eed33f351a6321debc6cbe4), uint256(0x08e722a2d01354f096ff5d0e22e077c37771f0d7114712ebe2125297c71105a6));
data[113] = Pairing.G1Point(uint256(0x0c3fc5b80bba7c638bf8cf0fc6166da12e733cdb618fc7e694f39d40e973defa), uint256(0x0f18dd89e38e122c7cf4f3da762426e55763cf457b510c2a58ea9872641a24d4));
data[114] = Pairing.G1Point(uint256(0x07b5cdc02b1e0cf1b8d433cb3a9ef5e9e39e1fdce16529447eccaa018e79866d), uint256(0x1001529eb88c96380c9301f860e9376ccf4c43edb6ce5733503dde964560c195));
data[115] = Pairing.G1Point(uint256(0x0e6ff2d62e7e99534ec8c863432b1c26a57627bed807d917b43b15125d5f8ce8), uint256(0x23d1d6aac44619d77689343208ed70ad04cac5be420eed85252905f4c90f19a7));
data[116] = Pairing.G1Point(uint256(0x1d9204172c0245678e406291ab86cc11ee54261ebefa96fba8c2fd6edf2311c5), uint256(0x0f34517518852a162bac312f7bf4f336c779bed3a53e473777c202711a2145d4));
data[117] = Pairing.G1Point(uint256(0x14528c19d7bee8fd426a2f1b6a9caac1842d2554e06e5258b2c35a4d52c71a45), uint256(0x0e91769e21854eeb091fdb02375a957d8d3e6a10816489e3a7c1e33f8ce51c18));
data[118] = Pairing.G1Point(uint256(0x0555ab398d020bd0ab52f4d1fe32279d890d7149ddf202a8eae2967d84846f96), uint256(0x29eee663c567fe622775a2b1dc2e91e1ddf332af22e899d9e261f4df6d33986d));
data[119] = Pairing.G1Point(uint256(0x2eb4ddd403d33e658701135d285235ebae0b258e0cc5e51e3bc5dd7ada6c86d3), uint256(0x2604c72b2864cccbc74a4b109c67d018b0a077b5dded584821860d6c0798d117));
data[120] = Pairing.G1Point(uint256(0x1eb57f7c36e368929b3dfdb46640febc38598ed118b086cc30a9192e163e24f4), uint256(0x252bde266c234653fd598d2442e939c8cbd199184dd2f9aa803e0d5d8fef8425));
data[121] = Pairing.G1Point(uint256(0x22ca8afde57fe05c3417ca9f4db5fbb8f92125765788d04ca02a57f841107dd3), uint256(0x256a0ca9457f2a683169f62e2f87ae1325600fae24663204586805f9898d2cdb));
data[122] = Pairing.G1Point(uint256(0x18c576d9d5b2cbe5b345230f17ec6b1ee27e5925de081888d580848e08c1f8ab), uint256(0x2e5772b6473e378b8d875d6a6d82868779cc7098bc77b68b1d938571d93b10f4));
data[123] = Pairing.G1Point(uint256(0x1fe9428cc085d3acbcb9a3b1c09a0e6028242f047704558341126ca47985db73), uint256(0x26a0749c1be8d312894e1967924196303bc85c02d526ff5967a5e2a77076c738));
data[124] = Pairing.G1Point(uint256(0x132d883ca1673ea54fc8f7e1e540c0a30cba40b1492fbc20f1dc62a987bcb6dd), uint256(0x1ab8fd469c4f476bddca6f3c81534099ee0fcd572cfc13ef1fe3a7f275f14cc0));
data[125] = Pairing.G1Point(uint256(0x2397ca70df6d88fb2dc7a93f299412695d188a38d4374ea8f9631dfbd06f4fed), uint256(0x1f29f608da347d19a4cc0cc1c7727be3115b3a9160a503efc4df5d05e9547a81));
data[126] = Pairing.G1Point(uint256(0x1a8c5a72a11a383d1b7bf9ddcfe106045b1859d59c4b5e71fff15a3f2e3941a2), uint256(0x2789bee01e816fb9de4140bd1f015c1c62ea65dbc7c4436cf9f5d063f49625e3));
data[127] = Pairing.G1Point(uint256(0x227049ddfa7162945ee3cb558630d80f46a80c8fc7e80526407cbc34b1451893), uint256(0x27a6f1d7c825bf0a1783223b03df2bc15ba7682e6997674ef22240cf7bf54989));
data[128] = Pairing.G1Point(uint256(0x21b03a1d526f13d600ca916ccdbdb17352893f2af6126e2e85b8cd3204b26cd1), uint256(0x19b2fdd3d241fba11f3fbfe146cb855a0b9fa209b3a43e9444fe46dcc4545589));
data[129] = Pairing.G1Point(uint256(0x19793fffe275bdbbb7887d7d1844e40e80b126993625f26c13f5ddd7aca6938b), uint256(0x2c8e0010e9c7b9fbb51c9dfc52df8040152c89d96b6145065bcc9e42fc3335ef));
data[130] = Pairing.G1Point(uint256(0x2b1304155011d8829fe7decb4ba5fbd68d17bc97c5036a391a054f54972ade28), uint256(0x16bbb62b4c636e03bd8b08db770a33b160812caec01b829d62d83dca6bcb00f1));
data[131] = Pairing.G1Point(uint256(0x013b4a21fe07e6a779f8d919069ad49201670feaab5526aa129855244409102d), uint256(0x16c3abe6811c8539417073b28bed19db37005de3e12d69084d1d5bc0b495486e));
data[132] = Pairing.G1Point(uint256(0x0e9c3332ec817b3a6b683b2bfc4de598aa3b24af40b747f29ea718edbcf755ca), uint256(0x11b7ede9f332ee67af25f46fbaff434e5d5f5ccf3088835ada5df559c9652819));
data[133] = Pairing.G1Point(uint256(0x21309ef65e31ea5d744574660ffc330f7bf27ee60f3dde5f75cf88df4191f888), uint256(0x143b3933d6b6ec8ad27e782fa1d65815ab2c48b08a583bce6cd3416084e28a08));
data[134] = Pairing.G1Point(uint256(0x0506b6958738152834f2961c3b7964980e41435fd18e253ee80611f50115e013), uint256(0x1de4cf8df731f2c39db9e30935a265fd0b76792b547b36b0c20d3e83512f32bf));
data[135] = Pairing.G1Point(uint256(0x1465cc7dd5ab8ab2fa67f347912cd164d4c9e0da58595ba28476e7764c3e73e4), uint256(0x1478c45528c2b5d3d149495d201da7bea5a4e9f07d4586942f8422965f030eed));
data[136] = Pairing.G1Point(uint256(0x2c2f6c12f985e067b096177b800880b801f273e931cde6de4e70794985f325cd), uint256(0x1185c59d80b5000598382e96ca14d69e74011a4a3118cfbec34be5893c8668e7));
data[137] = Pairing.G1Point(uint256(0x304bdf60dc946b658c51bc75f52ccfff3e3ffa0e287b77b370320a452bf55f4c), uint256(0x0e8e1afb1b594595f90e465c004fd4379f1e0e2e9d01bdbbd65f5b62936302a8));
data[138] = Pairing.G1Point(uint256(0x0ee5cf57756cb57e08f5a10929bee068686c206c03cb2b60de69ba5a54fe1891), uint256(0x0dfc0c0a5318da24dcaa9f1199798d8088b538e68c9df3f9784af71ffdbd348a));
data[139] = Pairing.G1Point(uint256(0x24faedc19467a7f6f9e424705fa34e44b2d6f7d939955365a0b3734d4b9ccc4a), uint256(0x27ded14b258909bab535fa6d54a1f53727a7ea2b84ec982b6be18d6d105f1a6a));
data[140] = Pairing.G1Point(uint256(0x2ec5eaa4906c84566e19c9ecd442ca5131f0c2c0826d87ae3c91006a4e20c6f5), uint256(0x03dc302553c082da5c7651ae9e1436eecb0ed7234ce5b26cf8e485b22ec2dfdc));
data[141] = Pairing.G1Point(uint256(0x2c1838fddf2a0b0d130f418628bcd26faffa58c1de2cc0e4ed9484f8452d8b84), uint256(0x24f8ee6889e8194873f727c27f742a7feccba7faa79ee8c37a93ec64cfa9ccc3));
data[142] = Pairing.G1Point(uint256(0x2643a0bf73795c0db11f1c632a56361b5f9e5eaa084aa0f2c55b3dffac1ddad8), uint256(0x1b9ad8b56eac4b5c5b3d9b85fdd2af2025b5cbfb15cd9f179e28acb43448c42b));
data[143] = Pairing.G1Point(uint256(0x0a05bf63d4c8593c5ce6812ea69aabf54aa8d05ccfca0bbc663787ac815ff3a5), uint256(0x20239a56f894d0275b7f9f261b35254218f8cb1766760e996d0de9644e67e03b));
data[144] = Pairing.G1Point(uint256(0x191f6d0de5ddb7392a4fe4031d7d3700baf8544f78c81fdc378974d4bbfa6a2d), uint256(0x1bf6dfdc24024cae63b5a63c7b5aa4861c7d541a592b5095589da8852bc7d727));
data[145] = Pairing.G1Point(uint256(0x1251a6248c100c1e205be86bfe5d30fcf9c2f86115bddfef48c10c1221dcf87f), uint256(0x2a50ccf3d4ac4e55aa9d1148c02838f1c456beb807710dc88f0cef3b36b4981f));
data[146] = Pairing.G1Point(uint256(0x26c7e84e471fe0cf67eb23871caa1481b83b6c0059d9ff2ddf88bc3d955be59a), uint256(0x27763050b035e068496fb172b7b3bb34ef2fcca3956b97fd67ed9e95b9ab6148));
data[147] = Pairing.G1Point(uint256(0x20b290dcfbd050a03a391b40b5146b274e785001ad50cdb84428437bbbcf76ba), uint256(0x12e8b109bf436e0d8f48f755623d6e6b86f2127a2f71650b4301ddc5d03149e3));
data[148] = Pairing.G1Point(uint256(0x2b74aa55cede3fde40b340062b6fd29bcc9b55e8c36fa18674f4705bf77deef3), uint256(0x026accd38b6e3d608cf7bf7a62addb4a2ad145c994422db94aa5aeb4e7c68dde));
data[149] = Pairing.G1Point(uint256(0x01fe756748802bc17a4d10e20a681bfc313c841e5c7356fa2ddcfbbb82cc27de), uint256(0x0e8b8b9e217cee75d80fc3e0c353d8d01926d2108ac4bdc77d51367f7e67e702));
data[150] = Pairing.G1Point(uint256(0x14edb2651aed3cec49012d1b2bb8dc9355aedcca704bacc89b840d3f364a5873), uint256(0x2194e09d8f7a1ee19316ddccc36076d4112137d190cb7951f48e83ee1cbb3981));
data[151] = Pairing.G1Point(uint256(0x2f96162dfc320012dade733263d156c39af2ca9588e6dadb34035a4ff5b47410), uint256(0x1bc57f6898b7e39fd19a24d0bccec4671d32718eb64a8d81b0640d5f2a55b496));
data[152] = Pairing.G1Point(uint256(0x23d092db13d26438c2404389c7a1ead4a496301b57871787ac6009d46a79e028), uint256(0x207dc95ebda51c99cd464ee315dfeb4bbbac5fa4c26f14b758cd8485f0354aa0));
data[153] = Pairing.G1Point(uint256(0x0e790f5a9c205aecbcc3eada2a8d5d5742fa0039497ba45285e11034129d93b6), uint256(0x16b9bfa2abb4decfc81d686a0d0ad25cba6b1cd3f5fcacd93d4c2866dfdda857));
data[154] = Pairing.G1Point(uint256(0x1bc2b2eb940e580a8a31208e00c80e4aea15518f315711ca39149f57078bd29f), uint256(0x27a113bf68b282e24edef88d14c52981a578bcdc9c0d406451198509b7f9d238));
data[155] = Pairing.G1Point(uint256(0x2d800b17deb5370a2f4c65a06d643142bc05aff838c10582568f2df7ed756264), uint256(0x2a21df5b10ce69aaaaef04fb257d1dba6ddbc4699eb9957f7a166c5fccbd6b25));
data[156] = Pairing.G1Point(uint256(0x09983cb4d2289100cfb5a0212757fb1a93831a936944196361da0cdbd84b9815), uint256(0x0da589cb7dd6b5c9e49c342dbeebbdb213fdfecb5b0d314438f2f317d3c629b5));
data[157] = Pairing.G1Point(uint256(0x045fa213ea30f1e80025b189fed97f62bdaa3e3f0f971153ae50460a9042a903), uint256(0x2e8755a414ea00f90e19b4d7e4b1f403acdd6e43eec5015e17450ead56b632e2));
data[158] = Pairing.G1Point(uint256(0x089b7ba740c60f737b80601f593ffa347c8f57cfd1c39e8b79d03fc3dfe9b25f), uint256(0x20136d707fc4d68ced99b76c91023c87679ca625bfb4f6337e4746f6773dca6a));
data[159] = Pairing.G1Point(uint256(0x24a3ff953a4531fd613a0baf38b5f78deb35214b931fa1b10fd6e006356ae2a2), uint256(0x281a26b357fce6f4689ad7a503f6d14ab3019ccfb67c102e6030fa1c5ae2d0c3));
data[160] = Pairing.G1Point(uint256(0x204b7d6a92f02ab9e17ce3b380a7f79c27addf24cbc10a91e50ba6fc1dc6c794), uint256(0x29170fc0ead1fffbb8588c716bbae22929a973affd65aabf1b50211f87826801));
data[161] = Pairing.G1Point(uint256(0x2d15c817088c19269866bf6ebcac5500ea701485ab0a758f7608ccf762368152), uint256(0x0759975e524a7b38acad113a0dbe5159272c933d3e71d6dd6f8fcb45b23aaecd));
data[162] = Pairing.G1Point(uint256(0x063a5cde90bd9f55f35e670192c1c92d37a7fe362a11a9d8abddab83e31906ef), uint256(0x07b3cb0a844a11bb53c73614fdcf8c2525c7ce0b50e35569c021a698ed1295bd));
data[163] = Pairing.G1Point(uint256(0x2e290252519c632fa81cc43b74b355da63a922ccf1763a34485ca7897455d752), uint256(0x2ce33238bf2350bcd208335697ba0f9d47a95711823a43fbb9ff822925686044));
data[164] = Pairing.G1Point(uint256(0x26eb481028b1d207eafa98267aff87ec0ff85d370533c17aa5b49df9efd5000c), uint256(0x2a30674aa4a3b7f016d9e6ecf22960c67b7a25afc6862f535bcc5de136acf3bd));
data[165] = Pairing.G1Point(uint256(0x22f1411c453a6dfd29a2686a959c5c5f2fd3edc7df86d86f26c2adbef6f17266), uint256(0x2c3ee1c9a4e2f3d6e8ae3a849659912c1c9f960f73a7fa6d2e323689615900d3));
data[166] = Pairing.G1Point(uint256(0x295136b9fb85eadd7413a4948e77148bd1c75baad7ca8503464558132856df4d), uint256(0x2ba30ed4849aca15f1d49e36779cfd00f4483600bf73b5eb440ae807258adb48));
data[167] = Pairing.G1Point(uint256(0x12015195aecab3f458dd5e2d2df89823ff9b93ec91e4de66de715aedff24fe6a), uint256(0x1e57a9af6d26103b9f9da0ac04e162806fb808ca4db6ef0678ccafaedaace0f2));
data[168] = Pairing.G1Point(uint256(0x208e12fc4e3be1eb8aeea1096cb883652f2a5e72c222bcbb76c8d688982860cd), uint256(0x2e146edef8a9fecde850926071ab78b35b070f73b6d1667272b450e3eddc83ee));
data[169] = Pairing.G1Point(uint256(0x28b7010f9f8fae89957fe2ae33117edd260007db303ab3ac9e866bc8be5852ed), uint256(0x257e721d0412e8f556120983e226afe7f517bdcb05f41ae955cca0bc97da05a3));
data[170] = Pairing.G1Point(uint256(0x1db409cf2c5d1a7f32daa58da6645ef726c00ed7706144a13431a6516e2eba06), uint256(0x22ca22992fffac4f1ac940457c8c4f67caac71dcf8dbe8de9a2816ea93b6662d));
data[171] = Pairing.G1Point(uint256(0x064e4adc48e2fefd5cb28452ae14d37ff5482cafacc9d08414c2e5d7c2573e8c), uint256(0x059bf91f01aa48cb2d617e670f565eced42acaa6827ad44e78966214c69b94ac));
data[172] = Pairing.G1Point(uint256(0x18039278fc12c4b89f03873b5a97392ddf2ea0f1d4e759819392e038807e4fe3), uint256(0x209eb3a986a9013dea65aa25a4937f87838be376ec42c2d1a19d1c7ce02fbd3f));
data[173] = Pairing.G1Point(uint256(0x1acf0b42307c2700e6f6535ad740339085e1f26ca0a8d1a698d1d4d642f13926), uint256(0x1ec92f3ecb231027f96794ea9a752bb31aa3d6dcb13f635d7b8cabbf30ab8d45));
data[174] = Pairing.G1Point(uint256(0x0a1b6b532372d30bace88f9584a18af3bed24e514fb1b0894a5352a622857788), uint256(0x0c014e3066412033dc0cca44fccf566802b7225f4b1f02f89fc314594b284abe));
data[175] = Pairing.G1Point(uint256(0x1439d84faf732a7e337ad954705838917d9c273b04c70bc6fc6fe9499d802fb9), uint256(0x300af3e69c1ffe34de27e868c26c5ab9204c94d031ac8d776115c888e042e0d2));
data[176] = Pairing.G1Point(uint256(0x118b958b0089da382503ca99e8224a0f8eabcfb663984572968f90964e826ff7), uint256(0x2152a66a216164df77d2998a5e34336f06b04c7643955d1a990e96df08c1fdd6));
data[177] = Pairing.G1Point(uint256(0x03052ed559ae0562354288ff72d4adf4ed33e6b6d7596814be3004ad81446338), uint256(0x16a49e8df3c736e8c0ac91a78e61bf419fcafcb492502353a77afc4713d4b64a));
data[178] = Pairing.G1Point(uint256(0x03c6d84de8f291fe11b68ddc3aeabe93c40d9323e9f5737e3b74cd6b67eec8af), uint256(0x242f0fcf43bf9fa3aca89a3a9adcab36543c6da16d7b099e4e4df7bb41974e32));
data[179] = Pairing.G1Point(uint256(0x24f28b3bae6ed91ed6ddafb761192625c2dabd9ec35220283612136246c72ae3), uint256(0x1e1d55a0fd258cfe8f3c3d33b7ab44cef411a5e1ba63e54479cb1e842ce7b4cf));
data[180] = Pairing.G1Point(uint256(0x292d5693260d851aadefde1a643166061d1bc35b57c9730ade1435a3d7d1bf4c), uint256(0x101e8a5c77bdd77510a8d468ce3cabe50c046a86781b46a5d73506ee9290394a));
data[181] = Pairing.G1Point(uint256(0x186b64d6693fa5e22898e15d87b36212b014145838d3dfbac09e27c1e026799d), uint256(0x2cd55e6682b2220b9744ad48c9bcaf5fb803590aebca6f565d6543ffd5325f87));
data[182] = Pairing.G1Point(uint256(0x29fbd3f4c71a8577b384852772d65d3ff4a207b8a889db60eff281b2fea952e0), uint256(0x2594dc623a406e551a42a2b78ba688b25dc99a2cbcd8ccf5d9dd8cf44a2a2ca2));
data[183] = Pairing.G1Point(uint256(0x0ebba74a62413a4259b398147a6b526e4653a02a16c7460634ba96c57b53ca1b), uint256(0x2763afae984637c4a081294a18bcc6d9951104c4eb0ccd460ef48d04b2a90382));
data[184] = Pairing.G1Point(uint256(0x0df1444df5ea39e8d41d237fbfb6b4eb028f008fe48619b5935289b90af7940a), uint256(0x25c0a220bcb08c8a6baaf6fb256de54158b1d932f4c66b0fcc6851d64d85dad9));
data[185] = Pairing.G1Point(uint256(0x1ce17cd362d3e5329c5d6138bab70f47f31c19e579c9d6848b8142a1962ee5d0), uint256(0x25a7cbb2ae0d8c760d0a55d9558d4e1459b2cc9801933bf2600fe772b0b26fd7));
data[186] = Pairing.G1Point(uint256(0x01029837474a5640bf0e7889fc27825c9ab0e82789c5c9c007b0f4c28c2a9515), uint256(0x1301fae75cc0bf14b6d1a1b321d250b3657661cb8445b3cb89e5a40461d63066));
data[187] = Pairing.G1Point(uint256(0x13806feac2cb55b73a65d1023ab1ac6c46e44162901cf74819d206e6c4ee4335), uint256(0x0c98bb70efcec48abe3781238bffb20a3c4ba1a59447fffbd8547737a0444189));
data[188] = Pairing.G1Point(uint256(0x1155d4df95803a614b92221b330194cfb2792ed7941de01b78b097031eea0b13), uint256(0x0983124e326bf453cb16532f92739b757c3fd2985582a8bf301463c0aff451fd));
data[189] = Pairing.G1Point(uint256(0x2990cee2b112d7a4dead7fd5bf4c66ab47c1066808884d7b6a16274a360a0c43), uint256(0x29313ae96a42d0f9868cced07b2815fda8a0bcbda4a813c01de0be57b498d4a0));
data[190] = Pairing.G1Point(uint256(0x245c0e1fe094433e3962195ad952052b83c7e071e16093d23cd8bdcf1532b3aa), uint256(0x0fa2b32a65e773f85ff5ea88b91331cee4299b105d744c799c96ac239f4487c1));
data[191] = Pairing.G1Point(uint256(0x1ce10aea3477e13085be7a00909ce4e192136c10f2572ce1ab0d7195472f7f4e), uint256(0x1193ff9198cca159ec70d4dacad055e123180f420a8f44ecae375a9660995cfa));
data[192] = Pairing.G1Point(uint256(0x12dbf3c13d4627b04200f06b942ff299cd417c9fc2ce77d50268e8e4ffce3a77), uint256(0x28cca6b0c13da66be5b21cf4858556973dcd1ee1a42b714da82ecaa6a6a975a5));
data[193] = Pairing.G1Point(uint256(0x2480d348bf1552ceefc5d200edcde2c8ddde69f44208028c68a9117d63e50620), uint256(0x217fd2580059b632e0177be1f2fe8e4a9b5743eb5e06d3f23c7b84f074d72124));
data[194] = Pairing.G1Point(uint256(0x07bede73b443f745dc4489936e9c35c7dc3a47290a911ea8183cdac861690a27), uint256(0x25bdf68fc894511442724d9243072bac4c0bb2fa3ba0d70a5d3046c56ead10eb));
data[195] = Pairing.G1Point(uint256(0x2a19c2b129d3c2c9f86fb17ab8112bd760ba6b5597b8307e61beb100b823f830), uint256(0x0e9e28fd825266bfabdd884e91519191b5c538d54cf08eb4cf5b5db6adfd36b6));
data[196] = Pairing.G1Point(uint256(0x099579cf507219581a7b95ccdedb9fae16da1c523e6df47ee766bf514991b95f), uint256(0x2bee302d4ed60de453a14712bae3a0881936a66b9acb7abc1b56dd209a009aa1));
data[197] = Pairing.G1Point(uint256(0x00ff19898c448bac7e4e07ab2f50dc22ef1833724b14661df9847c7d1ceb7661), uint256(0x1bfc85f0511c637e22b4b52069d8075d6a0a78cfe099def6626a48cd2a092ff8));
data[198] = Pairing.G1Point(uint256(0x27d4f68476726d43bfe3818950064e9d19f58853019a1183ac0dedf49ff6259c), uint256(0x2d8dc378734353a31bea9fec3afe3a937c724c4635d95ebda466d887ed7882f1));
data[199] = Pairing.G1Point(uint256(0x1534655ffcc8c3d37e784edee38fd79be88d05f344354a43f9d387cfa4f48538), uint256(0x1475e89ba589d61d7c1b494ec5da59934ccbd0e194094b456b6056280bc7ce43));
        
        Pairing.G1Point memory vk_x1 = Pairing.G1Point(m1, n1);
        for (uint i = 0; i < iinput.length; i++) {
            vk_x1 = Pairing.addition(vk_x1, Pairing.scalar_mul(data[i], uint(iinput[i])));
        }
        return (vk_x1.X,vk_x1.Y);
    }
}

pragma solidity ^0.6.1;
library GetVK1000 {
    using Pairing for *;
    function getvk(uint m1, uint n1, uint32[] memory iinput) public view returns (uint x1, uint  y1) {
        Pairing.G1Point[] memory data = new Pairing.G1Point[](30);
        data[0] = Pairing.G1Point(uint256(0x2a4f75220e3949ccb15d7f2e78eb34ddf803e95fa6db58a2bc679fbe9eb5f311), uint256(0x2cfccef399b3dbc50e0d5362498d85df710c17c99c0ce6c469742bc29a328eb9));
data[1] = Pairing.G1Point(uint256(0x15deeb0c12dac363e673afec9ec5d0a0f6f03bf3578d56feca9696600570a1e1), uint256(0x104ca6ea4049bbeafeff8d6c4c9e2161c7a996671ae6f3b5b154c2f491c26e23));
data[2] = Pairing.G1Point(uint256(0x2debab181e3b61a5668597ba80957d9bbbdaace84a5e5e8569620a32296332f9), uint256(0x2ce917a3177bf20a43deea735c71b6f15c9d8f37a5d5a2cf2f629667908dfa89));
data[3] = Pairing.G1Point(uint256(0x12cf369702f5940b26f45a236b0e3db382b16737304a8ec5a355730b9bd61a3c), uint256(0x04209f39ab32dc806a5cde197f25fa3ed455d0452b2c6767b55d5d624976d059));
data[4] = Pairing.G1Point(uint256(0x058fa6b7863735097b20eeb2671f99e5ab35b5fa4fce8b86ad451c19fe43fbc9), uint256(0x2611de54b4115fb81bcb255c0004a724f32b461702f7c1f006a1789a5fd462bb));
data[5] = Pairing.G1Point(uint256(0x080ee13deb6648065ae69f32d106ec0af9ac5460834dc56ad7b48ed89c1b42a7), uint256(0x0316b2e939f9a94553494a239bcf320fb94f6610c903898323236ca2cc70c4b9));
data[6] = Pairing.G1Point(uint256(0x00e81d817487c852d2d7838036307a201769de6c24dcc79076e6090a69b8bb37), uint256(0x28a9402479bd39e3c058aac61ce03fde97a75faf7ab326fe21f81b1eec55cc67));
data[7] = Pairing.G1Point(uint256(0x201a47645b007e5408d6e597b7d29c00239bc3554bcd2d12a4325c3f190251d8), uint256(0x2e82d34357d18137298ea983680aa665937c48e2ee2a848827b51c916a47e38f));
data[8] = Pairing.G1Point(uint256(0x23a831006fc3d186b0d92c6eab47d61cec44db00eedce0a3a9966b09b183b222), uint256(0x0c0999f2bca1616811f7a344e79a555402304081541554695ac2e821d11cdd28));
data[9] = Pairing.G1Point(uint256(0x2ce7d0424ef3ac0b04daebeda24e2a1d6d1e4410b71d116d61fee5686dbbbc4b), uint256(0x0c63818c74603e750a928cda398f5b8d1ea0948d6010cfebf06fb645b8f2dc7a));
data[10] = Pairing.G1Point(uint256(0x2be7fb95c7a3267b25386795e07e4d485fd9c73e0895d9b51488247ef0e8fdd3), uint256(0x0f67040f8b6e5cd6d9dc59187a4aefbba0c062d4bc01c81fc0c09b58fa684a35));
data[11] = Pairing.G1Point(uint256(0x166f27d517abed05b281f783575a32dc3ea61fcd390060c420f397a31b8e8164), uint256(0x11be18d8b196906a416277b59ec02a70d90f51787a094e1d0c706c9312d4eed0));
data[12] = Pairing.G1Point(uint256(0x2e6fae1d0364405becc3e55b048c7efb644219e5be8e7197402b1625459fb857), uint256(0x0efa380ef47266ec9521497ae8f5e985cba16d2b1e7963b6ef374934572b5c98));
data[13] = Pairing.G1Point(uint256(0x1ffacd2dc98bfeb8a5d7eee6bae2beef3e8e15932c125e50fdef372c79f7bb96), uint256(0x273476c3c3748b141edd1f18bc5cd02f36cc695ee67f21530b6f1979d6e3187e));
data[14] = Pairing.G1Point(uint256(0x29e6948f7c87ff31567417bba794da3cfdf331d0bc40a14e953e94792added4b), uint256(0x1a9a6230cfb464ca21ffb14bd3c018e25aba36ea8a2651d36642c08ca7b420c1));
data[15] = Pairing.G1Point(uint256(0x236076fd6e8fe565b8746812590293a3f73c3d711f0c34f135a6885c1f687fa3), uint256(0x1822a7b281108efa97439556af733465af9c0b519530ce220eac76943bf0e05a));
data[16] = Pairing.G1Point(uint256(0x2ed5454a0c5649b58e8002fed506f6d567281a95a3a4c819bcb993693276cef5), uint256(0x108ba15c5931ace21bca878c4832e8e67bbe695b864df4d1985b654b6c80b1a1));
data[17] = Pairing.G1Point(uint256(0x284a37d3ecb65eef3b7b1d676a2a67835467fed77f37477383cd6258f8420e39), uint256(0x273d8b5d29803a5cceee0978659a5396573b0e6606d0aefd7800117f2feceadf));
data[18] = Pairing.G1Point(uint256(0x0fca8d9908c5e9b67a446f3efdf3b45d5ec882909b2e8cd6e0b3f8d02daa4902), uint256(0x1ad92baf95ecaf096a72ae310eb28ee936b75661be7ed50605591bd7f4ee0151));
data[19] = Pairing.G1Point(uint256(0x1fd587597fa2c0c21257aadac225ba438a19fc27b93c66a7b0693dbed564d2b9), uint256(0x10b52681710ef0a1046617a86741a37b6fccfe45b7e9c0e2e152873fe3ed3b00));
data[20] = Pairing.G1Point(uint256(0x0484dddf09830b1694064d4504c68c8130becaa3cc88bb88cc82f7783ef82aaf), uint256(0x29b9b575009918714cb2c8d696b4d50872ebb5cb47e48e38dcfc4056ee2eee12));
data[21] = Pairing.G1Point(uint256(0x2809d647c788e08cb135eba36d09d0f5abb784a1fb0cfd9f46bb9fe7ebeb7e6b), uint256(0x166eea8937277798249d380e9cae924bf39cfcb30d75e89634dc3a5fcba2f306));
data[22] = Pairing.G1Point(uint256(0x077541d2041eac50b8f3c839b55226a6d82879fcc7240f259ae3980885f77fa1), uint256(0x2984dc20f7f5684ed1bc53a3b2d8573fb7962800320ed270944f6bb0d1be2fc9));
data[23] = Pairing.G1Point(uint256(0x0bbfa394baf79b5f557dccc2de1577ca814aa1078ad7e3f1f92293c163539f78), uint256(0x081ed575a5dd2274de30e086805ad4bb360a92d90eed8e3292653f1048485617));
data[24] = Pairing.G1Point(uint256(0x00b99f5a85be53c8142e0d409facbf115bd45fdbf26042402a6e5aecc9c735c9), uint256(0x0052ccdf5b1771bc41c6d607ed330d3f1b8f48a4ca17e4dfe054878a20ae75f7));
data[25] = Pairing.G1Point(uint256(0x2a56376a39f3a90f0726cdeaf48c19cf862d8e836f8e29878464854a696dfbc4), uint256(0x0397b9d8ebd2d5d7a00fdfe9c4e275203d9ea5a931f0d2528df26c19039c5e2a));
data[26] = Pairing.G1Point(uint256(0x29c90cc0cbcc9905a52d9e3577d2f791c88b0cb97d1fd92dc1c9e510c9cbd918), uint256(0x0dbd3a56ebc9b7be8054810b5cb9f1f0e30c8cf078fb968d390485f2058032b0));
data[27] = Pairing.G1Point(uint256(0x00f51eb06dbf4f63c4b28aa0eaa03a43693d3b832cf2d423da243ca9079a339b), uint256(0x1f840cf7f9b77193ba8867a732733cb2c1f03c21f5c3045ef2c87de0be9958e5));
data[28] = Pairing.G1Point(uint256(0x13eb627ab5d6d92c2cbf05527eb48266a133e6fe71df8d7c8d69405f492db8e9), uint256(0x019fa84f3ba909b842044694b8fd6cf35bce53ccf6b50ad849555e57cd3b13c2));
data[29] = Pairing.G1Point(uint256(0x2f9251aa4f2c1354747575d1c9cefb25aafad01a57ddd71fea088152814ca9a6), uint256(0x2d1423ea28672bc5494af16cfb285bae4a00fa50e72a88e81057825abfdcfbb4));
        
        Pairing.G1Point memory vk_x1 = Pairing.G1Point(m1, n1);
        for (uint i = 0; i < iinput.length; i++) {
            vk_x1 = Pairing.addition(vk_x1, Pairing.scalar_mul(data[i], uint(iinput[i])));
        }
        return (vk_x1.X,vk_x1.Y);
    }
}


contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point gamma_abc0;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() view internal returns (VerifyingKey memory vk) {
       vk.alpha = Pairing.G1Point(uint256(0x0854119314830add171109084a1543345a209d25efa1e9df088284e1833560e9), uint256(0x226e86577ccb9eb494b7bbc371c4e2d2a66283903bb11b675efa8a4235d21c4f));
vk.beta = Pairing.G2Point([uint256(0x05252db601874090df4682eb48badd8df025797deea18d35503aeec322a86a27), uint256(0x02397c5ef83e851695c75f0cfe5358e0c97c8db03a0dabc57e83ba2ba1b64f6b)], [uint256(0x000d5f314c8bf36eef3c035699fe7772f0cfbe2f4606ffe460055dcd59295654), uint256(0x214b9891409533c75e5749a42ef8213b8f827a067550e3cadc5491dbed24a563)]);
vk.gamma = Pairing.G2Point([uint256(0x01351d0aa45017045f63723bb7c6ad95fb2e897ea45bcaed55308f30e7ed3e8a), uint256(0x0510d318d0640085d8ecd2eab723b822b39e6e99fc54e6ad05f1c778178c3ffd)], [uint256(0x2d13ff4bb8ed0a73b8070a84a825cd09b652757dcedd99a3a339b73d11aa126f), uint256(0x007632c34100a8fb1d959301300a9f1cea4ba50a01efb1e15f6a0b6f7e327174)]);
vk.delta = Pairing.G2Point([uint256(0x092205a67fa0e3923ce753d561bbae0aa80edda226c2f748df909d621ed1ceac), uint256(0x05cfde0813eba942cf58b45ff7c119dc07f544bf28c30c029b9b8f0d7cf382a5)], [uint256(0x2591c785ce14c6299e3dcff492c5def7aa0f49bcf5f734f29e56cbe4dbed4395), uint256(0x28c0c205d4b7e26841ce1285835ce94e6f382dea3a3fe2839da2b8266d2711cc)]);
vk.gamma_abc0 = Pairing.G1Point(uint256(0x2530ddcdba1d91592a31280909e68446568ba201cc7a141e67e8f53de43e775f), uint256(0x0d39b64850ee0f60e8b6e235f9999ae615bc52a9cef923e593621c6b735c8e8d));
    }
    
    function verify(uint32[] memory input1,uint32[] memory input2,uint32[] memory input3,uint32[] memory input4,uint32[] memory input5, Proof memory proof) internal view returns (uint) {
        //uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        // Compute the linear combination vk_x
        uint x;
        uint y;
        (x, y) = GetVK200.getvk(vk_x.X, vk_x.Y,input1);
        vk_x = Pairing.G1Point(uint256(x), uint256(y));
        (x, y) = GetVK400.getvk(vk_x.X, vk_x.Y,input2);
        vk_x = Pairing.G1Point(uint256(x), uint256(y));
        (x, y) = GetVK600.getvk(vk_x.X, vk_x.Y,input3);
        vk_x = Pairing.G1Point(uint256(x), uint256(y));
        (x, y) = GetVK800.getvk(vk_x.X, vk_x.Y,input4);
        vk_x = Pairing.G1Point(uint256(x), uint256(y));
        (x, y) = GetVK1000.getvk(vk_x.X, vk_x.Y,input5);
        vk_x = Pairing.G1Point(uint256(x), uint256(y));

        
        vk_x = Pairing.addition(vk_x, vk.gamma_abc0);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c, uint32[830] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint32[] memory inputValues1 = new uint32[](200);
        uint32[] memory inputValues2 = new uint32[](200);
        uint32[] memory inputValues3 = new uint32[](200);
        uint32[] memory inputValues4 = new uint32[](200);
        uint32[] memory inputValues5 = new uint32[](30);
        
        for(uint i = 0; i < 200; i++){
            inputValues1[i] = input[i];
            inputValues2[i] = input[i+200];
            inputValues3[i] = input[i+400];
            inputValues4[i] = input[i+600];
        }
        for(uint i = 0; i < 30; i++){
            inputValues5[i] = input[i+800];
        }
        if (verify(inputValues1,inputValues2,inputValues3,inputValues4,inputValues5, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}




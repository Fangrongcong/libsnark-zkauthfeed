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
        Pairing.G1Point[] memory data = new Pairing.G1Point[](146);
        data[0] = Pairing.G1Point(uint256(0x0f837737814d360c37073863e709ad9614afbef2cbeb8399f0b29af8041a2aa9), uint256(0x001378a89394a02634d35cfeefa8e59adadfd0ca39365873942c8db23c475829));
data[1] = Pairing.G1Point(uint256(0x259b2dcc4f1d4dd24420722cf2527bc93ecf537d23801efb6fa43d1827289f63), uint256(0x16719220749299488227c06b5a2c9bcc8280511ad0ee813a049e57a9011c44a5));
data[2] = Pairing.G1Point(uint256(0x07aef54fbf3573cf63cc89cae235b0adddd0bb5d6ae87d4e45aca993823aa872), uint256(0x2bbfab01ccc6c3e69e407e836967eff736286e3931eaab6b76e59c636aac8b74));
data[3] = Pairing.G1Point(uint256(0x0534c1a6dcfa7feeff4c40097369f7ed50d989aedc73b60ab2a2706d3d8692c8), uint256(0x101728ccf2b299b8ff11917fc0a1d26c09c19e07d642292c546cd732c1f00b9a));
data[4] = Pairing.G1Point(uint256(0x0bf99b301d28d569043dd530fd8e399815f84bdcb21a42a851b52e645b5b83c2), uint256(0x298b945fc39ed899226e60222439f38ff88b55004fd064c2021ec557e8dda1ca));
data[5] = Pairing.G1Point(uint256(0x2e7364b9c99f78acf96b133d06e668fd9c32750b886519f7cda534cf4df21718), uint256(0x11047bdebcfc977f014cd0e114856aba34d5514fc2938de9e300687b59df3bd5));
data[6] = Pairing.G1Point(uint256(0x09ff346982b0a63f3300a62218134cd661f2652831e54fac3ec2cc3c2ece2cc3), uint256(0x2311eada96221a68beff56389dedbc8f62c15afd4843e79cb74f792f26f065ac));
data[7] = Pairing.G1Point(uint256(0x2d51dc8afcd0730e56701197e73d914b945aa92eeb4e654c39f0da98d1954eae), uint256(0x20adc42a673970d2777bf8f5d868250390a4eb8ba94df27593ecd33f1d8f2679));
data[8] = Pairing.G1Point(uint256(0x0c78696c7b962ee2edb83be87a83e490a6d93d998f7ba7ebf1196fdd5567c181), uint256(0x1a639bf878ca9d0060509d40efc2a920b7a8aec53652dcc437009612f3203351));
data[9] = Pairing.G1Point(uint256(0x2cd0b6a37330561c148dbd9b8f3f34d7f4d8cde610aa60c144bb2c1f8766e00a), uint256(0x2a9bbcbc63c959102481d79cc64d77ae1795928c604dbbc49d400f91bb895104));
data[10] = Pairing.G1Point(uint256(0x1039b6335d3edf20cbbe0c2dc356f860b0fe1c009abe25f26c8a0e1c4374c21a), uint256(0x07930293ed3cbed360b19b59c0c220dd1646861b865bbd4203fc319a25f8bfb0));
data[11] = Pairing.G1Point(uint256(0x28a0df422a819ba6f4f4b11ff169c178874a8eb5888c0a015f9f3a8c490cbfb7), uint256(0x2cbfc65535d3f2b2fdc099acad8f5fd14dfda35eca1525a642f34d9c7ea689bd));
data[12] = Pairing.G1Point(uint256(0x105e910f334e099ca1376e0c54a631fb820e2dfd96d47c244b06e1adb6a73388), uint256(0x2cde0e327ee788cb8d0bb4b531f90b0a4cf77fbef2ceb02c64ac8adcd435d864));
data[13] = Pairing.G1Point(uint256(0x0d20effcb83fb3f7e31675b27157e49703ead27ff75f81dd9295fd0b82b23813), uint256(0x0e9440f1770538e0cc9a9a8f8fab26bace50e18d52d271d8d8fabf32c29c03a0));
data[14] = Pairing.G1Point(uint256(0x0e3e975b4eeb937415c2d4c7aa4c0ee66724968cd97ca0902c487729d0a6c469), uint256(0x2ddb21c815aa61acdb9ba5c153e89f5ea974698b750db577e389efbde27e916f));
data[15] = Pairing.G1Point(uint256(0x2c97796a6ab378428aa5f93e51d8708598ce8f5611a84f8fe4eeb1aa330a8055), uint256(0x050df611b463af4ac67eae857014854340e7df37e9cc0cf68c739337e9753c64));
data[16] = Pairing.G1Point(uint256(0x1d8103ae8427e0b42b3f764c8f713459167e8191aafcc761b7b2aa3bc2d99dd0), uint256(0x10b57889dfabeefd9f40def3aec0014c5c9dec46c1d5fc247e87d64d30bc7831));
data[17] = Pairing.G1Point(uint256(0x1a19fd4edebf0aed7ba5d9a35189d190cf33288344a50418caaa875523c768fc), uint256(0x26fb1872899dbef5d925ee2c38ae9d3e7b9414e7dcd5dfe0c0cded450239c913));
data[18] = Pairing.G1Point(uint256(0x1a2042eeeb5544ff599cb6d40aef83377cfb5993a1b32db7bbbfe5b39e2ba044), uint256(0x052781c0fdd1cc01c748f325be3c7ca0b00319940c7470622d8392391ba89cc8));
data[19] = Pairing.G1Point(uint256(0x13c79b60b8a9e97b4d09da7d3d8d2f7bd21ef5ac8d1aad48c1dffc5d6b0d1a03), uint256(0x1e11c3e3ad44e6b57a2c190fbc15919682135f4631dc625af9dee96c07ac03c8));
data[20] = Pairing.G1Point(uint256(0x0e60778f3aac5e3ec4396362ae0c8ba381989df9e9e6c826dffa965e9957e07a), uint256(0x1cba27ef31e82ae965e00675631238e17729272934ec79c4de80636cceaa6a9e));
data[21] = Pairing.G1Point(uint256(0x199c8ffe02ccf51827bac09e759af5220c098376acb3114f582a4025aa7960ae), uint256(0x28dc7f2b5cc8f318d890b617315c29552776f50f5ebf57119b3d6f899b61ef8e));
data[22] = Pairing.G1Point(uint256(0x2fe27ccf5dff162a178b0a5ae4a42688b7c244bd238df553bc99c881633b58db), uint256(0x0fdb70b31f6de7245fb0e36c27a1fd6e20b085c80ad85ca1f0546be8e7a040d0));
data[23] = Pairing.G1Point(uint256(0x18dc5a4cd4a0817a2238a64c4ce608edf24737e24e4b50ba11d5e59ef630c1a1), uint256(0x1383161395c1261d4884781e8f30e35f3f02af0b9bb94fc18c055ad92b8a1a3d));
data[24] = Pairing.G1Point(uint256(0x1404cb9148f15289c17201f9d964c1accd5d57b431b04e4cbd2846b493e80c21), uint256(0x2d9c680b1630c5307deb63f5eddf15761caafcb5cdf8e4dd2db688497197d3f4));
data[25] = Pairing.G1Point(uint256(0x21a28fe9a78129a2f19d7e3b885ea97c57fb123485d3010fcbf5d80320455cd5), uint256(0x1f8ff966331e6ef33240b9d0206c1d130ffe963cc088aa7f8637ead2367f6595));
data[26] = Pairing.G1Point(uint256(0x2dcbbf311fc89fbe155a12b73d57c4b562e05ba5751d14e019a93c0e617c3dae), uint256(0x14333bc87cb92a205736173c65b6199442cb55c89d21d3d1061588cefc26d9c1));
data[27] = Pairing.G1Point(uint256(0x07522640b5a084ff71ba9e571a97428fe8933383d1dc9f96555e497ccf982491), uint256(0x256bfcd7d49ff66caaa16a56702c5ec0d5c79befe7b9df0239c5c36f87081f86));
data[28] = Pairing.G1Point(uint256(0x27f085fc812e0925c1c649677b07c0739c1607b273a978afea3063b457781a17), uint256(0x259b83b668454e786965648424c3ed073cc219825f4e74e612068e374a3cf2d7));
data[29] = Pairing.G1Point(uint256(0x13d20343bb713244f44f459b5eb4068cd0d3b7c3e9e63e2088841209f69f234b), uint256(0x21df38a7026c4a9351a6c2d882cbf46d730f6b5db62ae49b1bab3ba5d21b547d));
data[30] = Pairing.G1Point(uint256(0x1004ae9867ad3b4029ad330f6f3635e8c371e02287f5e33ec256185d921f5baa), uint256(0x1b450597409ff755a05819b7cedb06457d9db9a584a7939a435fdc0fd69b3fd7));
data[31] = Pairing.G1Point(uint256(0x03db5d69dda808b338d2bae69457e15a93f354debf64cc7ea407edafa1d5d2c2), uint256(0x0f267a0f4f84dc125fdf831026df8b6ff611fb20b51d4dd6492e534eff949fdc));
data[32] = Pairing.G1Point(uint256(0x0911e0c48834f00e66227a548fe6ff0807d57a697ff62e2d9c32076c7a4d15fe), uint256(0x2d22322b949c01ff2aad0012b84c53a6e0e07205da464bcda2e29df692f5925c));
data[33] = Pairing.G1Point(uint256(0x023f2dc30b2870a3485e880715a4d04c97fd6226cb8137aa7ada9972da0379ff), uint256(0x177c1dd831dacfdbc3ac6c5e57d9ff54b5bc365065d21509cb2b5ebc83db5c9f));
data[34] = Pairing.G1Point(uint256(0x219f3ff0a2c9d7b00cd9fe2796e02cce6ea35be71e051520b505eef8381f8df8), uint256(0x06990ce322592d9d34dff63ecdc2385623acc658b36371bc1c5ef10ea0b81166));
data[35] = Pairing.G1Point(uint256(0x249f3c41fa3582cb31a6914bb6a246bd623377afb59a1af644be41ca1e97d677), uint256(0x1578a7a71d850648984508a7e5b67712da8f3bc9d7c7c73911d95c79fc09f585));
data[36] = Pairing.G1Point(uint256(0x14792ac6b4dcc0b7854bf605c9b4fd0135383c91b323b1d7966f7f5e2c54842e), uint256(0x17f904aeb2b72ef134788821b310067a309af3d6d34838f308301e045263cda6));
data[37] = Pairing.G1Point(uint256(0x03bb245d2dab98ba4c34d1633452166391f895c08596dfae8b6c8048caf30b50), uint256(0x274f4522564af989392d2bcc2dbb97e9057a630b336c70e9c4866b5f3dab24d0));
data[38] = Pairing.G1Point(uint256(0x1595ace2c0ff5accf336d77f0bfee956ebaf10e5cd53c8c514b0271d73a1b695), uint256(0x09263015c1920c56edeb05d053086e3accb53f745e80aa0804996cb3fcc1a5de));
data[39] = Pairing.G1Point(uint256(0x05c7592db271a2be9eed51bb82b30d45e91d23bbc97836ebd2500e777ceef017), uint256(0x01f2d8fb8ed8a65059c09fd1b497c84784a080661b6bc0aa01faa9b6a4040f3e));
data[40] = Pairing.G1Point(uint256(0x0211027c7c06bb1811623dea26475957e8a3eeb8a26e9fe7dbd8780196f0da91), uint256(0x023f7cc24b48372ecad85dc3617477768f8525353432fa632d3303d221d646bb));
data[41] = Pairing.G1Point(uint256(0x2312cb3d236e286fb3bfba35dceadcbb57adb82b642d14dfd7091755f4287828), uint256(0x06872546a61cd7ca48433fe664e31fe005dd8964b77f0e6313deea50caa6d259));
data[42] = Pairing.G1Point(uint256(0x07baef3f55d0c23d16069b3ca0d24b1ddb91111567a837490562e422cc5b961a), uint256(0x239ee08d50855ecd14ad9afa1130afe0b563f2bc2f0370ab467f78be18f37c54));
data[43] = Pairing.G1Point(uint256(0x099b49b15b05d036476d95344e29b97082f833f4cdec15b55bc64f2396ae8424), uint256(0x0005bccb6a21417c8f608fa0ea0463c24c10c8e9fdc631dbfbe8d8ab28633184));
data[44] = Pairing.G1Point(uint256(0x1c19cf699ae5ed2eb67e8a398dae3ea30758022de1a9e5e7776f9de738be69dd), uint256(0x11e6b7cfe42b33dbbdf6cb01990ccdb6a4cc55a5154cbb0918c68f4dbd004a8a));
data[45] = Pairing.G1Point(uint256(0x0b819ecd659022e272bd3458f0e558b88392a405cf0c066eb435a4f92c3e304f), uint256(0x1a2598ba5839e56d4e94c712b63a0224fbc96d45284cbbcfd49a6d4f366c3b91));
data[46] = Pairing.G1Point(uint256(0x0580eb68de7a15a77ddd49e09bde8328e273d4db2af0aecaa8e6116ece3177cf), uint256(0x191ebafe811230c8a17d47892802d90d3e56d9162f6054e19b90cdca4711b3dd));
data[47] = Pairing.G1Point(uint256(0x05d2bf1e8218c085b9571374d5e1902a8afd3bb575ae6abf81922327b60a8031), uint256(0x16af6f0c397c5d16d27e59000914b8ca33fc6c5b0196e29b2dd6d24f76720973));
data[48] = Pairing.G1Point(uint256(0x2d24634a0a202186824b6224962e59b5e47522af0928eef5234fe8333d18bf20), uint256(0x0b2a5928571c5f12593b66451e644eaefb7f0b6cd4ffe992e2bf311c036894db));
data[49] = Pairing.G1Point(uint256(0x0ac91f4938d9e8aaa3cbbd859900372ea92ab86844d4ecc69f9fd55b9eae2043), uint256(0x14832702068d058dc657d25a72103084d3b72e4147ef4c586511590c2aeab205));
data[50] = Pairing.G1Point(uint256(0x106018a333016deccd49c905fdd6621f116fb67958836bbe4a7960c88e048006), uint256(0x017c508bdc72eda1bba3f3cc432205409beac3b42c9dfc319c51b6c483385b4f));
data[51] = Pairing.G1Point(uint256(0x1652ece8f3e7243fdcc4214d1a321e07f6afcfbc1ae46b3cb0e760b43c39bebd), uint256(0x1320a5ed09481318c2723e885a1470a43970a559415bd0acc3a37f965e6a95fc));
data[52] = Pairing.G1Point(uint256(0x1d0cbb0d8e07ef52f548e7315fbca36e3f4b7d4736be1b5a0488fbaf7ce9f8ae), uint256(0x144d3d0b79d0e6cf1159147c332f38774390367de79fefabbe7cbbaba8013fd0));
data[53] = Pairing.G1Point(uint256(0x029a0e68a8a38a28dea6c478a1ef0af89f8f17928d2932518289c26718a751b0), uint256(0x244af7e6ce53da207d486feed5502e9997732ded522710e68b90f569bc7ae1f8));
data[54] = Pairing.G1Point(uint256(0x086ea899a4ae800bc7772dae85f569c7374318f55948efe0590291f38f0a8d90), uint256(0x2dbeb9362fc993cbc0e82e57a68aa30df8ab4081e21dc1671ca7af55769b7316));
data[55] = Pairing.G1Point(uint256(0x117b42ffc96d64f1d7f7986574dec1f39187da95033ff53d86e63d297a2b43c5), uint256(0x159f57a24d306d0ca950b219fca2da9a9b03ab7ac2a62986cc9b6d6d48975262));
data[56] = Pairing.G1Point(uint256(0x1b28b30d3d43766b81f833eec2631ddd746960ca7324d1f1b617b431af4700f9), uint256(0x0c80eef549426ca8b3d5e1fda4aa6adbfd1889ed1a1a2d957a008b886da4cdf6));
data[57] = Pairing.G1Point(uint256(0x06931cb1134bdda3e2e6e336a88d30f70b77e6fba6156c4a705f2daff8ab9c9d), uint256(0x0c442235925423fef059eb8b2430fccb5a2f9c00615a1dc090ef7d6c251cf79c));
data[58] = Pairing.G1Point(uint256(0x014885f6259c57c1d9e76572027dcbfdbbc0e0ddf9644802871ccea0f465a226), uint256(0x29a4a61311e16cd9ed858a960be71f0e90432f996b3b3debdc315bd8af2a91de));
data[59] = Pairing.G1Point(uint256(0x16f0ad4fc71b1a93e7ce58b818e80c23158e3b089ce0b9292f85974b9a7e1188), uint256(0x0081554880eeed8a05f6eda679b42280224caf99b627f9ea80250bbeea0a9c01));
data[60] = Pairing.G1Point(uint256(0x27a9c5da880d87cf3ae4f23da92a31bd4b40b3dae318e509689a47415ca38006), uint256(0x036b2ac9158dfe07434a29697efe978a353cecd00b695a0cbff1e027de7173f1));
data[61] = Pairing.G1Point(uint256(0x1a7138e1d4871e11e30f2230614c0eb30a46b1cf19ca7fd05d2a7bc012629dc7), uint256(0x0ba6cf26ad3cea0451116825da39fe23681c0072bdec3e95c7bef068005b8b73));
data[62] = Pairing.G1Point(uint256(0x2b37f982c877008695edf574b2d59f8c6dbd8167add3f073086dcd57d12feac7), uint256(0x160c6821355b6c11ac83d00c39dbfbe7878a5ebe6f9abc0a2372c799cdd2b011));
data[63] = Pairing.G1Point(uint256(0x153891145f5cdd3bcddda0793571f2d1c52d1447deaca2bbac19c56b1a524293), uint256(0x1d169b7be16819741cc1de610446b7c6b511313c8d7924249497904724a594fb));
data[64] = Pairing.G1Point(uint256(0x2900a42f3f17ea1dc4a5a99fb901098f7d216c626831614ebea80ba9f5a3f79e), uint256(0x025127b466524dd17d329e71eb6bb9c51d9ed2558fc501244a54b88543df475b));
data[65] = Pairing.G1Point(uint256(0x251de296534f2874c281e3b8fbe60a99910493bc98560f6f9ecad25d655f7fcb), uint256(0x066c5865d66de1184297a1395c1323b80c511331af862717e14557da77080a06));
data[66] = Pairing.G1Point(uint256(0x206f9ff7352bba36c3ea30ad89949e9da01b725982a57b7223ebfe7b9356829f), uint256(0x1aba59b6bdaa8b61edcdb54bd2d59c333d024a7aa89a72ac63b71865f90298e7));
data[67] = Pairing.G1Point(uint256(0x24e46c14d8b7bf4a3dbc5b8f028a6fec5085bcfa19823f74583a633f12564d38), uint256(0x1a5974f3ae36e298295e9772675b4dac80403b3db87ac577d9afe9c11d0801e8));
data[68] = Pairing.G1Point(uint256(0x023be0a0cbc6b5801bad0947d558583c893174330c33a2669d1f3b07083baae0), uint256(0x047f9ba49433536e67d671942bb4408231c9bb45fde38eabc70b788808c66271));
data[69] = Pairing.G1Point(uint256(0x0fb7580310e9be050162879332307c2c33cde0b61e9c81fd17154aacc695e015), uint256(0x0f7509d02311d08ce3863bf926cb238d698cee145e082706dd623097c12facbb));
data[70] = Pairing.G1Point(uint256(0x008a4deab857dcade9faf99213b9f2a5d7bcd209c9266c13a07654987a24773b), uint256(0x169ffa6a40b820d4b23920d181894f2f9ba26995f303bf3e3bf5b4ac1ff6e830));
data[71] = Pairing.G1Point(uint256(0x22d12ce759e0b0d496c4ffdcbee57a97b3412fd6b7b9a9f9309702391e70ad75), uint256(0x18f158062309448b0b8f0ecbd2456e41fa10ef4b4a419b4e244d7f1fc59f865f));
data[72] = Pairing.G1Point(uint256(0x1927e1ce22e84649d5c75c09fcafc2227383a707c0cef504878be2744e549f7f), uint256(0x2fa187d27406225e86047469b8e8c1b6daf5add0d010c076b09c69b391020044));
data[73] = Pairing.G1Point(uint256(0x00db68bb04785100d459ccb588e32aa5fcec388fc8db674d0ff250cddda56f89), uint256(0x27be0cc2a913144eca97a1794a8c7936348cdae0bd7f07f406c2405aa8ac6044));
data[74] = Pairing.G1Point(uint256(0x04fd28183395f5d80ddac98aacf1e7023b84c94db5ccffc2025fd3d490c66897), uint256(0x2a0d04512832102008b3ad1e9a521070cf57b1e7b39f833438d57fcffbb5fa97));
data[75] = Pairing.G1Point(uint256(0x019c700b6dc1a6f8181873d4666747e64b3ff2fa2b373b236bef2847329dbabc), uint256(0x05201095ef9beb9e1c396223f6cd62cf4cd0ed0786fd9314395fcb2391a3e24b));
data[76] = Pairing.G1Point(uint256(0x1219ca2a05029727b6ceeaf9cffb6922046d08f1f6e9e98fdde3741b6cb58c47), uint256(0x040ce8b4fd36d752efa1a43d0a2d96d0bd0793030edff566cc21fa0bfb04b118));
data[77] = Pairing.G1Point(uint256(0x0ae193b6a26e2646e9a15497542e44e090d1a5285f9aa95ae792df157367d1ba), uint256(0x1c7ffbd245794ceba7c595e75950319a7c6a672eddcdeb93636b1bb7ed8341c3));
data[78] = Pairing.G1Point(uint256(0x0002d14db8a9edd29f9d035d858afef1f25aa9956a773b949452f4973cde44fd), uint256(0x0212b5d3e50e0a3c0f0a16803d7e4b9ee1c722b7a5472491a0d1f92d3e0d8d51));
data[79] = Pairing.G1Point(uint256(0x281c66cb5e1c9e699bcfe6d6eb24a17eecc49c4eab4cdd5adb79c3cf95f11246), uint256(0x057d10d2da29b87c0a0ba9d202a7829a45d2c9401f7bbbd6cf4c9f939c42d7d2));
data[80] = Pairing.G1Point(uint256(0x2be7073ce4835ac36f1f0021de225fe19c88de9551d80d2c2c9fe652a63fa1c9), uint256(0x0271a710f541acb4c15c776547b58b05541689e41914b5d51d17b40c1bc981bc));
data[81] = Pairing.G1Point(uint256(0x170257759213ca8f3b1ac60354294b8211b593744150685f42563f0767221f95), uint256(0x0852cfe825dd0491d759ac4e7e5bf3d678165f8ca4a9b175fb2909f87ef63294));
data[82] = Pairing.G1Point(uint256(0x163044cd1bb1e07e1f6b485552f731878e39f721c3404403279d4b63881bbd2b), uint256(0x1f9a23239114513cb18dd465826b63f61ddc29a12334b74c339ad06ba203bf8f));
data[83] = Pairing.G1Point(uint256(0x07b02c16f00210814167c3bb8948f610033930e455228438c3f3e9981b59aebe), uint256(0x1fe93b78c16344f77dc9b329caeaa795626b87d383e7904577d79d352a12d591));
data[84] = Pairing.G1Point(uint256(0x1f47eb3d52ba3723b07576e0ebb1534d28f8dd0bcd272da1c90002da6d3135ff), uint256(0x1e143865fbeead00474a9965d0a11e8ad034cd277062f07384548badd3d9934a));
data[85] = Pairing.G1Point(uint256(0x30542c23a459d0027ab93663b158a21616144ea581d30cf240f4a7697ac8fe28), uint256(0x097fde8b3278dbc43b754f5b4dd5948f9e4c9ac218a1048a0ce90f5d74bcad10));
data[86] = Pairing.G1Point(uint256(0x13ebf1b5fee49740ffc7397f6e2ab9f4aa9b750431a9eeb9ed608de439d2bd69), uint256(0x2e9a8ba64c6a6a97270cdeb580cff0d948c0905fbf7d26e6398c865e5f03eae8));
data[87] = Pairing.G1Point(uint256(0x2aa4a5a741eca9fdb859bf37a4de0b4cd0f98b29cfc185b049db4ad1bf780506), uint256(0x0fc28f4a0bc6aa59a24b0406a86611c95049f0704240048b7e5e8c5bce6381ef));
data[88] = Pairing.G1Point(uint256(0x29ad31e8b60eff49bfedb554694272b03a9d44f5df4789e0b5bacbe27b9dcf26), uint256(0x081c01c93808115929e733294aafa0daf96d4e2ff1530257d0641baf9d4f9693));
data[89] = Pairing.G1Point(uint256(0x0a5cfca1cbbc2cb09ca3e929ed3327d3fa545bbfc907c5c822b1231b327f34e0), uint256(0x2c58832b97a93dcb06d584621593e7e5c6fe2f8ebcb931375fec05f2e4f2d347));
data[90] = Pairing.G1Point(uint256(0x2bd9743a5a355c5301d9a2ce80d49248783a87d5863a325430c30abdfa121143), uint256(0x215b75d4c11b10d1181f70a49f5ca2611a085f16cb5c1233973b3c0f506a0c75));
data[91] = Pairing.G1Point(uint256(0x1e299c7fd4f858e953400d12a57c0867b45186ebb8040f3cf2d9d3aeba741a30), uint256(0x087628216073787704be5751b09c0fab58c26ef10838539ae842965b47d549e4));
data[92] = Pairing.G1Point(uint256(0x29ddc1f1e62402efc1bf27e32b817ee3a2b65cd16d941f62ae7bb6a114e3e7cf), uint256(0x2716a608dffcc8283a661ce7b0bc815797f090308c3511568cfbccd03c2a7c4a));
data[93] = Pairing.G1Point(uint256(0x0443bb400ed82de4ece2226b6ddebaa015e038c4cfb2a8d0474ba8257302246d), uint256(0x0fef40c91da20b16a7922fdda4367fd4a880ca2e092ed079054ab94d806ae4a7));
data[94] = Pairing.G1Point(uint256(0x2f03187ae852bcca7f9f1d6365c5a8cdf14edc8aec4ea313aa4e7b104742f2d1), uint256(0x1a8673f8f3808c0595ceec5e37adcf0fcddd2a79e4d612bdf83b23ba25f81f2d));
data[95] = Pairing.G1Point(uint256(0x1d9daacf9a447189d730785b5396266c5800c4a8cea8ead327ba821ca071b731), uint256(0x020483845f547b536c90a624e9453939052644616fef7a9f547da968fc11e16a));
data[96] = Pairing.G1Point(uint256(0x2365343761eff33939b6a89ed1384b2536f340e0919ea7c66d35b0fc85200a42), uint256(0x10bebee6536a1cad2cad0d89016f7e98b6ef923fba3762358b4ae0f3d1c6219b));
data[97] = Pairing.G1Point(uint256(0x1673abddcd342cdca1849f21780f71398b8ffeb5fdc4bfb15ca7318bafd4564b), uint256(0x042681d248b1034739de49b4c807a232b8e74bd3f35452698502989795462c86));
data[98] = Pairing.G1Point(uint256(0x25d49fed6c795b6e865cae772b55cc2edcd0ffafbd142f583f14c5f873cf6fc1), uint256(0x23682adf4a63b4299c69c06c64ccc337765687c27d4474aa9f73a20644fd13d8));
data[99] = Pairing.G1Point(uint256(0x182846da742932c87b4c3b128e338b485e20e47580bb816a2cf296d4e88de9f2), uint256(0x2916f3a9d3f77dfcee3ba19562250c2b65969e63220de97c0d071b4b814deb02));
data[100] = Pairing.G1Point(uint256(0x174cd568632419736ced6a462df9d554332ae08e9a02dad000b294b77750c48f), uint256(0x1b8ff72c25e2e7e16a43724fe370fcc01eba56a6fe8864d179908b332bf49796));
data[101] = Pairing.G1Point(uint256(0x256ba1856dbf7f82dba82ce87e9aff5bcf5c302c78038b72f4189815b27bbb54), uint256(0x1fea8728237fc0144e7dafad53744021439075b14b7d1b39ead8467636f9d63b));
data[102] = Pairing.G1Point(uint256(0x2016668c9598b27f80de28eb2829f924bb314d9dd0b500c7c6318353a399295d), uint256(0x0b0ef2378ba9e44f3f6ec8f2ea457d1d13b24bda17a2a9e34208652f1ea33a55));
data[103] = Pairing.G1Point(uint256(0x0cec7721b8ff07b25b3458ba9830d4491f83d59c7db1a6b145200571dd7d75e1), uint256(0x0d8bcbe09ab5cb114d9767391f743fd8c5a4ef171c8041a015d16dee3984e4c9));
data[104] = Pairing.G1Point(uint256(0x04da4dc6fe2e98ce0b000f3b840e230e1b091f48a90963d41898b21c6a01d6b4), uint256(0x0ed4630077bf0fecef37c5d74a8b4c6eed30bb8a7da5879b88ffd4fad3907e17));
data[105] = Pairing.G1Point(uint256(0x0a7823e028733bebef5d413afe6d7c74731388464478c8e873936386e9cd0a52), uint256(0x07a699ef375628a6750399c8a5a29a17f7930cb5bc8aeb80602aa87ae1e802de));
data[106] = Pairing.G1Point(uint256(0x190de70af857601bf41c25c1b167863100d5a24bc6735b2d564e0f64802911b2), uint256(0x134759fb592fe76b1d4a7b7d8fef249e1f34b9c1c930149aa0d232b885d554de));
data[107] = Pairing.G1Point(uint256(0x0a464b7a6b0d56fb701035b2593bfeabb71c741c4ba9881ad16c86055d69501d), uint256(0x19e7d21098a6dff368d954ac622affb672fe896366132619c9036c2079b36e21));
data[108] = Pairing.G1Point(uint256(0x2523c272c7746e12d8c4cbf1ce319cf0f7b18364737843590d5e417b56b764dd), uint256(0x0862666f2641a470565ff9000da104411659b83c8c087e284102ca66731f2a6a));
data[109] = Pairing.G1Point(uint256(0x2ea8443745863a7e9bedf8ab579aa5609fef4aab0e9d77830c91e9ddf71fed83), uint256(0x2cac31c3256cb7736acddd929f7530823669514ec15397fa304b2445b5f407fe));
data[110] = Pairing.G1Point(uint256(0x1df80685ebefff8eca6749ee2a10a806fac326351ec093e9abdb38c688b07bf2), uint256(0x1daa2a4e79a66fb329d14e8fec9278b151faa5e6cbacce01ea46556a84728594));
data[111] = Pairing.G1Point(uint256(0x2f572055118d7c92797ba2c0dd3b0a7a6dc92a59fe0eb7487a39b3f21d0968d0), uint256(0x25cca951da1aad9cbbc42057a1c7b0284142bf55da3f3a1111fc6f100ae8e22f));
data[112] = Pairing.G1Point(uint256(0x218c4f5e5cbc9492e54fcbcad8e9d69fa820b890db2e4f28d18fc2ddc6173457), uint256(0x1bd3d0f0d30547562bfe4143c98caf29bc6c73963e6c36bdb9e40b283e88f4ed));
data[113] = Pairing.G1Point(uint256(0x1b21e5a58e3fbb1f816be594a93e254e0798e8ab9f153dc8b12a2b3ce3b3cda1), uint256(0x2dbcdbc2f73e589bc2e721fb88f7bf1c7eb21fdf6e5c26b69fda8537dd0fac41));
data[114] = Pairing.G1Point(uint256(0x1ea7ba4ad7f90a30eb4c56461af1f5dd7d2919fe8c7dddf98e59f9ba23783606), uint256(0x27f1592817a261a9fe79ec1a5388b6bc09abcc289380314ca8550226b40c201f));
data[115] = Pairing.G1Point(uint256(0x2b489fa283912332b6cc32c41dff5e077993eed61b911c62a4f8a6069547aeb4), uint256(0x00a1c99c7c5d75f9c32cfead3568eda22970af221e45f8fc9f41a1f016d441a2));
data[116] = Pairing.G1Point(uint256(0x27d852a7aa6dac61523e3c718822292705b01c9de5e5fa5f4b186ef08de464e9), uint256(0x2810ad4548af34ef43a7ae4552ddc077ccd2382fb8a3b34102729c7f45a14ce3));
data[117] = Pairing.G1Point(uint256(0x2cf1398018d06d318fb67240931b58fb00beb5095e8a6a2d79bc0e71995e79e1), uint256(0x1f2c48730c550014ec4fe8290973799181cb49858e834de579154c040147e7b8));
data[118] = Pairing.G1Point(uint256(0x21dcabf75144986e6e989c4fced458b61cde69ef160d524a5df8755bcfa2445c), uint256(0x211f120e77b4d035466b696fadb0e97a1d154781dbc1508a29da05d11ec1de19));
data[119] = Pairing.G1Point(uint256(0x14c03d546866c954febfc42507715580d0014e75e44bad687b5c6881b6930be5), uint256(0x1b12c9a7b4f09231717604a3f4c249122d2cf2e41096dc23fd36e6c87360b45f));
data[120] = Pairing.G1Point(uint256(0x09a20b9ec626826a1c86ca2e43468712ba69a1f555331c2ed610378fe345da5d), uint256(0x0c211dd4f9cdb76f7b1196ea1120fa39421e380dc13132c6cfbb37184475c786));
data[121] = Pairing.G1Point(uint256(0x1ce2f630b573c7b8f943051f3353998cb733d35c41a6bde990a8a73b2c267ce4), uint256(0x258e21d6ee0781e00c02b52367af84d668999719560bc7ab210ad0704c946f38));
data[122] = Pairing.G1Point(uint256(0x04d86cce3da8eac88b13532dcf0499d9d8d678b334a7ec57d81ec43538afed67), uint256(0x07ab7e6fb2806e7b6995b473a171057fe1bec34480bf40b987892275195f704a));
data[123] = Pairing.G1Point(uint256(0x0762a2b512f6d6ea1ce09c541546b4e09ea259c369d2fa70da241ea9c8114efe), uint256(0x007311f80043413e79884297842dcea634cd79bbde2604c81d422aa9823aa9ec));
data[124] = Pairing.G1Point(uint256(0x2bd098e9ead9493912c60af8030f3481d908540f5b0e4348204ad8b6edf020eb), uint256(0x0fc683673c967fbd40dd1e95af11021c14e7803fce07bddf561f8a51af8f8ec3));
data[125] = Pairing.G1Point(uint256(0x1a478f7bb9531c73d1ea8ecb14f7bf69f2ac27300813e78f6f963a1cf8424ad2), uint256(0x17965fc5d83b42ba0a6a2b7e67f644d040ba4f2050df71bfd869d1ea7910beff));
data[126] = Pairing.G1Point(uint256(0x10b8767202b8d044171ad87f94d782c4879afc223e78b0cfca0515e9b45bc6af), uint256(0x2c981d7ec33fd421cceec2b2335538bdce6716e91682c9787525a8933e654bd7));
data[127] = Pairing.G1Point(uint256(0x2f4747abca44235f3ab397666fe6a0958472e9ab3b86d4fa54c47332bb8dce83), uint256(0x215b9dbe317c582a71f2ae4fd609524e8b4dc98c60aa3c628134651002c73850));
data[128] = Pairing.G1Point(uint256(0x152f6cf86756485f0a7f1e883e90840966149670833e44cdaa013c9da9e96406), uint256(0x0f478c0b7c2c340197d9c22f997416cd46460eadfa0ddae73d8cd86b68a2ffe7));
data[129] = Pairing.G1Point(uint256(0x14a8b3ad428d0021bae144598461dc38141f2de2591f1c4beff8d35ab32b70a2), uint256(0x1feb13f8c0a4ac528ecb3ae9bafd1511b4e864a07f5353cdcc819163317d3a59));
data[130] = Pairing.G1Point(uint256(0x26dc7fef4744d9552572c130b2f82b9816d1e3b44b2699184b5d5048807cf7df), uint256(0x0db535c7575fb3f1d8b101a0e75cebfad79ff74ae89568bef26b40eb3c816827));
data[131] = Pairing.G1Point(uint256(0x24f26b8b351d5355c5ad6b0b1af62e6614fb07aca192362345178dc7e91f5c06), uint256(0x172282a3eb65cd5610fe59e3a83df94a23481e5ffd4c31f1034be12a90e6e0bd));
data[132] = Pairing.G1Point(uint256(0x1719cba220991963afcc49072350970ffae94a712d12ab78559d611e482ebcaa), uint256(0x07259cc5173e1d664707a3f9353a4242f44b8c2cf1b08ad2b2e14f1e3c408542));
data[133] = Pairing.G1Point(uint256(0x1d086609d3f6d64e5bba34974e74192e947994b4f8ba2b125ae9747625f914d8), uint256(0x026a5e6158a334cc9606e5ff49efb1c9aaa764554c27ba7b182a62d04889744d));
data[134] = Pairing.G1Point(uint256(0x13583be76cf1f053c7f63d5c701c29cd4cb17b582bbac7d711f3724a281979e2), uint256(0x213665e1cf6474d258dd8819439b7745d5c0c012dc2f3cb561d04f210b46dbe4));
data[135] = Pairing.G1Point(uint256(0x21f8c7560dcbb36b5c1f904b196da96ac34bae5268100c6b96f1c1bf025e7b43), uint256(0x07a2ea049629f22b764e6fcd635edb3e824e116f6ec4535c131c7de24bff9cbb));
data[136] = Pairing.G1Point(uint256(0x0209d411141f33941838a11d6d713515334fe81c017c1223e9d66afd3a9c36a0), uint256(0x171dfc91bb98d55c003e65457868e40926e6a77c4518d3e658dc03564ddef8f9));
data[137] = Pairing.G1Point(uint256(0x03663bc2b48bac79ff8d129237e694a8913c146e438d5019f94a53c43aea473d), uint256(0x1bd0fb4d4430df15b484335f45755812ee7b62cdf3d35c779cd5f24612516d8a));
data[138] = Pairing.G1Point(uint256(0x032cf8a8976cb4f47e0235ec4508d97ab98e3e88bc960069aa30ff1ba64bc9f1), uint256(0x15958364bc47af54d81d1f237c3971925f8305b0e195b1718d01989cf67d7f38));
data[139] = Pairing.G1Point(uint256(0x0046b60cdbc464e773fb8e28262cd172680efe004d97440c7b3d500d83e90679), uint256(0x0c5f9c03b1d18fb0b8140baa365e9b3d6fa178f70bef9db57b3b35841c58aaf3));
data[140] = Pairing.G1Point(uint256(0x0cd300086b61b673c92ecf7c140d05156bdf88b3f15f386ef755269ff43743b6), uint256(0x02fbed4812f6a9ab6818636dcc9b7491306563eb7ef043796ebb1b1d028fdfbd));
data[141] = Pairing.G1Point(uint256(0x04f6200681c0ed5b2f2c21e052bb55321d6676c1e8112bd742e022cc223fd55d), uint256(0x093c82795435c90aec26ed93060b442a69bf3d3f3f24bacefaa250462158f6cb));
data[142] = Pairing.G1Point(uint256(0x23533cbd8b6ffebba08f0a0a1a3a53ab34300537ae5c65aef8c7bbc661eb75af), uint256(0x01054fbd3ec502a70a104dce5b3ddb47e2f022167893d85f862286e4845ea809));
data[143] = Pairing.G1Point(uint256(0x0e5a30904bebb7822a29034eb487e1a1d59cf4677f5efe239ecbf45ae0c60022), uint256(0x158271a6790b4f390e01162e7f113278f536c003b489821813290802ffe3a5a1));
data[144] = Pairing.G1Point(uint256(0x28257a691468b7a85a02deeb85e64b2b3876482b09995dd12fcab1238ccf3782), uint256(0x25a4503661ad655aaa14ff3394af05d9af6d0aaa9330db85b0e53eaea450f92f));
data[145] = Pairing.G1Point(uint256(0x234e756729606e373672daf9aebe57091ceb13895761301122044f562f782d4b), uint256(0x024affa571ea05f25dbc845cda108802036bc741f7d54cc2d6d78cc46aa0ea2f));
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
       vk.alpha = Pairing.G1Point(uint256(0x10842be0413d883f46e288bf7054291537270c9a151fed7b008d62ed0684d3a9), uint256(0x2ba1b1348f5496c82eda8820ff5a5e80646f4ec5409b3f32528e115e11ce0688));
vk.beta = Pairing.G2Point([uint256(0x13b138bb16e7c6ed1eff7bd178cb9e4f493808257f263ad1a721254e0932de46), uint256(0x2f38dbc9a6538e983475cdb1008245f0dc0d0efafb618b778160d0285f445f5d)], [uint256(0x0456971af127b2a10f140f9903204589ef2f532546bcf889d33064359342941c), uint256(0x10110a1f1b5c3a025b1590a8a2b7083fb55632235432ad8944db211fe9536e0b)]);
vk.gamma = Pairing.G2Point([uint256(0x2a6f97b93a0d814d0bb69a883bb0cc27656bd0f8348bd67d0fe107a37f81eaca), uint256(0x10adab9aa6ff87716801cbec22253c360c1937328388a5c2b87c2e9c1b488610)], [uint256(0x2f863640cb18d42c93db7cf452a56aa39132f9b9a02d7f0691bd1702723ac996), uint256(0x2220d8a144ac5f967267982f36ee10f5d4764e7436d9ef5754f16d06e16de874)]);
vk.delta = Pairing.G2Point([uint256(0x1a8aa238b2fa37f89504872270ab52a506ea8510f6a40af8e9cbb1f0ad12d0b5), uint256(0x0d53c01afa9d5f8369ad8047e49837fd052f384ac991252f9fb1f5a1fe27f19e)], [uint256(0x0f5caeb3016bc5e961208b434f2a066ac15a655508e9bfbb92e3b6c6eb0d564e), uint256(0x2ad45b1d4136d4505cb9db8742ee1c22b621f083bcb9aa600e8c775f69a2cc69)]);
vk.gamma_abc0 = Pairing.G1Point(uint256(0x26f477ff6da2f43f9232b8ca39582450ae9639182170b7c3ea39a0ed2e31f159), uint256(0x090ff6aee1a9a375cdc07cb84373b54f4384f9049182374b18589983646f7c91));    }
    
    function verify(uint32[] memory input1, Proof memory proof) internal view returns (uint) {
        //uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        uint x;
        uint y;
        (x, y) = GetVK200.getvk(vk_x.X, vk_x.Y,input1);
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
            uint[2] memory c, uint32[146] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint32[] memory inputValues1 = new uint32[](146);
      
        for(uint i = 0; i < 146; i++){
            inputValues1[i] = input[i];
        }
        
        if (verify(inputValues1,proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}


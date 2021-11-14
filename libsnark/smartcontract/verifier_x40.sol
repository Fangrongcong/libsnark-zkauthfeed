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
        Pairing.G1Point[] memory data = new Pairing.G1Point[](50);
        data[0] = Pairing.G1Point(uint256(0x0192179ce5a114f2e6750536514f5efc8ad76d1b63edc93e22b00f474f7f121c), uint256(0x24d5198251271600cf3c7673661cfe311d5372c3946570387ac8f9aec5560eed));
data[1] = Pairing.G1Point(uint256(0x1779ab0886dce44ec50b224f664f0ff38fa2481a924c4b417d1457994323ab58), uint256(0x05faa17cf3882be7b53be8dcb125b8e469681862eaf1e1a828bf6bb01108bc5a));
data[2] = Pairing.G1Point(uint256(0x2dd9cf798636bcfe3bdb3719b40b7c7885d67d2663c9336d61d2238950c3ebfb), uint256(0x1ca7058a5649dee85296374cb61bf316d87f4c17910a92752c4e324e24841c39));
data[3] = Pairing.G1Point(uint256(0x2a47ad36987d3750199831e92f97e68d9669862f06778291ce9070ac5a105753), uint256(0x2b76405c7953d871ae09ed2c53e497942df1684235c62021ac11365b82684fdf));
data[4] = Pairing.G1Point(uint256(0x0e64a7cf3baf8130357301b99a686b01c6bd42a7c9a47eaf8417aa25b8f8bba4), uint256(0x11b87ed2003cfae9d2e8eca2f224ff2ed9598432dd0276389599e9e5296c3d1b));
data[5] = Pairing.G1Point(uint256(0x1118f4cfdfde10784c32d6ab3db7801ba68cecc1ed8a6aa84d4350548df7334a), uint256(0x2d6f0d89e6d28bd5a21cb4703ffc93b9c500cdde188524f55b1131ae871956a3));
data[6] = Pairing.G1Point(uint256(0x0ca2becc22ae9d1ae6ae4d3697aecf004bb16aa70df638983795856154000472), uint256(0x1f756f8de95f0acde566308fd5ba340018f4a489e627057716d8323de5c6ea39));
data[7] = Pairing.G1Point(uint256(0x28afb5ceea23edb3fe351d5c9de5cccd8a780db5fc8de967150d7e7af561413d), uint256(0x1670d897e3b0ca51900c89c18b3071032e969036cfe73f6fa6158df0fb80b17e));
data[8] = Pairing.G1Point(uint256(0x2221ad3f5913711a8ace7c69ac94d3ab2efe58e575673638f5881bf8c867eedb), uint256(0x28a426c5a82b17487e13e54c9825da6f4bb00520a60413fcfd31f2840ad66992));
data[9] = Pairing.G1Point(uint256(0x0b92b7bc9ee7ae4af1d2b38416a5623ae3a8809d0642885371cc96afee35ac89), uint256(0x05a636a4a235d70a17c116ac50c71c4d1927b3b2634b94eee65a8185a5ba6331));
data[10] = Pairing.G1Point(uint256(0x1bc780e3c49596e981d15261e6ec18fc83c9dae3201c171506bc0309522ec51b), uint256(0x214efc4403b01b6dc4e4260375cad94873d5ad28f9f51edfca1e7451e0e161d8));
data[11] = Pairing.G1Point(uint256(0x1af66f186dcf437a1622bca60ba7355371d3877b380dfb4a3ae9ea9eae4264a1), uint256(0x036fb390639e54e056bc0a6bc1fcf83c97e162581a9611272012ef617679c87f));
data[12] = Pairing.G1Point(uint256(0x1671b9c4d23aad688c786973a28d3d9bfd348d164298c362d5ee38f62860d456), uint256(0x1eb3b456a191b27310bd0a7fb09030d87b5a66bb8ffdaf2d65ce20452f88a87a));
data[13] = Pairing.G1Point(uint256(0x2af43bce5d5f8c71d534286b7bd298b30fdd9f0f0bc8eef911f7d232ffaff2e3), uint256(0x0c9b799a2634e517b533351edde9f61aea887602eff1d60e8fbbd689de6d4ac8));
data[14] = Pairing.G1Point(uint256(0x268e3006bcbb359964b05ecc11cde6c3ca19add29b15b7bedacd925ab8ee7ca7), uint256(0x269adf777c1a0c4042ad6a8be1476135f2a99deacfd4cd27bb4a85a2e37362ae));
data[15] = Pairing.G1Point(uint256(0x14469357b76757a2eadaef37897b119e28d8f02479eeb732eb295cfa7c1f183f), uint256(0x2595b9ca2f9c4e3ba204e5fd1d084eeabf477fe8526bfdeb7ffa4d3722227291));
data[16] = Pairing.G1Point(uint256(0x03ce2d9610e3c098e8b6153ff4b7f3e24cb8b2da894fc7ac73fd635c2cce22a7), uint256(0x0d9515f285c0ffe6121bc13c22b776ba72828794fde8ae61638a5c2cc120377e));
data[17] = Pairing.G1Point(uint256(0x2cb8457a8971f025d194dbc6040ef5b76fb0a48abf47c436fe5d90444f0a63ae), uint256(0x03aa1bc639023ef2c16d6bb23b74282498b9fd4971b50323f930b46a8aa14314));
data[18] = Pairing.G1Point(uint256(0x0db600705839c70aea406fd974aba63f5a374224f909aecb64177546e589e95a), uint256(0x1c848fd8d7dedec18968e0118d889f542602fcd1c40b4b5327ba3238c6b9cbb5));
data[19] = Pairing.G1Point(uint256(0x1c960fe632287c75a20cb8a4205fa8a5d0a3f3f0418c76c6364ffbbb6e2f65d7), uint256(0x2d2173a2844cf71dfeaeb0e5aad3f9fe28bed63259d0fc56e909c1c8ef736ad6));
data[20] = Pairing.G1Point(uint256(0x2ee1101a70858cdfc2551f2d007e420fe88a900e03b62e44a1aadda08fe4724a), uint256(0x2a2a362bd9c0d44aad1153ae665c8b27415cbbc752febddca235401deedde741));
data[21] = Pairing.G1Point(uint256(0x2951a48b445699cf6f1618a6dbcc6b6767d8bc2c59bf0ece929fbaf3371b9a35), uint256(0x2dc3b6a1fa788db1f14f7adc5aa3c6cca685c66f482aa78f436972614eefd659));
data[22] = Pairing.G1Point(uint256(0x14d33161d23efa2a323aab8d5a7b197f75e59186fa3ec98a7303f241062d872a), uint256(0x2217201fdd5c84ce04e3ba5fd9c7d826348edb71a8d0dd054ad07dda90297c39));
data[23] = Pairing.G1Point(uint256(0x04fb3f2aea3db89a5c21bafb8350511a42b0fe30216994ed3a5cb92480d696f6), uint256(0x20c7381475173f5b916398329b38089ca41449fc62bf8137b111e454efcffed5));
data[24] = Pairing.G1Point(uint256(0x198183943770c26a5fa6efc93eaccd32028c8c6f38de0b85ed17aa4aa0382f28), uint256(0x037b67d667689cd4640ed4d96d1c4faf36d84c829ec16bcfc4715461ac8956ef));
data[25] = Pairing.G1Point(uint256(0x26dd74d3880aab5a3768afd24c6afb9c323c8d79d02832800c5560c3834f59be), uint256(0x035a4e66f94a6a8159803fcd6bc64c6ba81520bc8fecdafa0fd0289ba7129e8d));
data[26] = Pairing.G1Point(uint256(0x05bf616c1b8ddc558998bbebe4db924d469e94844539d96d396433a5d74dde74), uint256(0x045c1fe8efcd2704f71f2188e19746d689657fce411b045aec147878f22034fb));
data[27] = Pairing.G1Point(uint256(0x0d915c44b68db2d5069c79d1b370b8af218b3528e95b0eca2ed11e3e01e5b5b4), uint256(0x00ef7d981eba86c8bbd8dcf728645871b3239e738819d187fceaad975d4ac5fd));
data[28] = Pairing.G1Point(uint256(0x099172e282ffc9966cbdd17b5802b1f2ad320d6efb8e09956b262d6db3e120ec), uint256(0x2187a9f7ce39c28e226c8d5171c17b2ed913f30053bf5421b115cf87ae693f1c));
data[29] = Pairing.G1Point(uint256(0x29977c5dc49a574f03e8673788b9f4a565338abf708cb39e8e72125dd4bc3cd7), uint256(0x2c3274cc7baa1e6e05e4ed7e01c86f2fe036683bd6a5ca38654865f5b617b837));
data[30] = Pairing.G1Point(uint256(0x0f3a8acaaecd44dd3ae7049bf7f8f5f3a4aef195b3d5d1608dc12cbd9b993e99), uint256(0x1fa384e259f3c633f0a721fbab299f7e62450105afa0f34028d24075eb0d6c19));
data[31] = Pairing.G1Point(uint256(0x0c80197c53fa53c9c2954f6c788b136270f947729800412c92a061ca043e0fe9), uint256(0x1f6b687b91fa7b2d1a4ea4a921b67df08ca0e72d7b04f6c471d0af7e6119dd9a));
data[32] = Pairing.G1Point(uint256(0x0578ad5d9608c43ee32bbc0b049609b3f5ed838f305dda44dbdc4a59da4e68ea), uint256(0x2a99de43065ad676d717cf0c4690a1f57dbabd55d479b06933e0ec033ef7a030));
data[33] = Pairing.G1Point(uint256(0x04e1d00a389e60837d4cb6f5bc379a57d82e7a1617feaf91de34325668b1cba9), uint256(0x290198e467ba6ed8e24e17fc04d281bf464a875f966a92fac3acbef2f6bd2c76));
data[34] = Pairing.G1Point(uint256(0x2e46db2901513065d6fb996995fc2a7b581631a679f3339cbd6682b5052e92b3), uint256(0x062c3819868b994cdd3b974306f12f59db77eb8dc26020c9502aaff2a7ee9ea5));
data[35] = Pairing.G1Point(uint256(0x24fde09b9285f1f2488a2b3fc7b4597f002f9bc085424ec3fe532a82411a92f1), uint256(0x1380e27ad293e4e8e1455af4dd03ac2a39e8c5a79f6a44668d672e98c65d1bde));
data[36] = Pairing.G1Point(uint256(0x0c932d412080150d0d6e12a0c06be5679b3d2285342fcd8c237299d50087e7b7), uint256(0x069e0dbbd79918cf65742f6eca3da2bd1c6dcdd2d2b7978afea4271981f8e026));
data[37] = Pairing.G1Point(uint256(0x0be1b5bd46d1b2a2334aac18a58bbe7712dc90c2bc3663f067b05cd0457ce587), uint256(0x2e3e4e0c9b1c6f05d5a6ddfaa24ba8a3a029a5d306ad8a6f942cda3e646579a8));
data[38] = Pairing.G1Point(uint256(0x0222450910aae815b5fad5c233bb4650bc02e9963ce943c8f1c6647e571bdda0), uint256(0x20d1c99fe329bbdab5d8507139d257a02bc3509983e24217d76886119abe955f));
data[39] = Pairing.G1Point(uint256(0x081b6e4da04932855689668d01bbb3a8bbefe4e1a7cfdb8f4e1b3b0b1822190b), uint256(0x2553e5ea891cee26ab28ad046433c3bd79fbcb00dcff2d71997bfe145a26edf0));
data[40] = Pairing.G1Point(uint256(0x18e973f179024b4ac3db9974580db12deb24154d17ececbef910a67919053faa), uint256(0x17cf1f647c5dd94fff1167961928333e96b9e9ad03b0a6a5a98a03ee289ec636));
data[41] = Pairing.G1Point(uint256(0x1cca9f89b4c60d937451911270ad3a066f31081e36c22e223d5b3c94eaed7b56), uint256(0x14747c3562153a06f801b25fce8ce1d4dc160767347c838200449402a86553e2));
data[42] = Pairing.G1Point(uint256(0x0d084b72dac5581751ec98b7618384f0f5fff079f6d8e212e7640f8bdb9a4060), uint256(0x27315a787ebdf5a962f24b27c213b31b1ef764e5c07c9ad67e137f2e3cb653a2));
data[43] = Pairing.G1Point(uint256(0x22e4e9d620c334e825b12f4c64a0f9ed80a881073b9bb415bfb6f93a1652b445), uint256(0x04e92e6eeb2cfeca5ee53b89ee2f9b1a40a8d55257ee7288d3f4de90744c6a5d));
data[44] = Pairing.G1Point(uint256(0x2905dbf750dc5e853e170fb31dcd958aab5ae9cfc9f65d7811d913ed06bafa6d), uint256(0x2fe96e6323f145f5c8c06b45525886e740efcad209ebccaeaa3bb1017b26c648));
data[45] = Pairing.G1Point(uint256(0x11aa218af6c6175fd8b05092390371b7c6ef967915eef9616f7aafb2a8170aa4), uint256(0x00f67d90832f2eb432b88f970ba786de86f738e21ed0cdaf9054f6111f2fee3b));
data[46] = Pairing.G1Point(uint256(0x2fb12161f38e7d8bb83041afba21c2f6cfe5cf959c91aefd6f4517ef275396d0), uint256(0x24911ea7f7f09077b3f441d7e83fae6c9c47436907ad89474ff30b5367d0dc95));
data[47] = Pairing.G1Point(uint256(0x20dcb9343d1695e07fbf40fd1a9b724679358d05d5a52e4120aa28596ae627f6), uint256(0x13e0f8da26e50a5174317f03fe218324bd358ab7d90b7be3ed3d639eede3aa7d));
data[48] = Pairing.G1Point(uint256(0x0d4af920fba4a5e06f6c4954240e31fd511a04bad1b68cc1c7d57a7f9f67e539), uint256(0x2e33ca96fea0b85a89d8942a59ea0645d49098ac7d34bfbe66f25c1cb82f2342));
data[49] = Pairing.G1Point(uint256(0x1b42f8649b30f7bb45e173b71f247b290680e315f435e3de7f1de31d68f17323), uint256(0x2422226e33d34176cb727b9b69bf466a6d761fe0d89b1d4b904674888d6a7273));
        Pairing.G1Point memory vk_x1 = Pairing.G1Point(m1, n1);
        for (uint i = 0; i < iinput.length; i++) {
            vk_x1 = Pairing.addition(vk_x1, Pairing.scalar_mul(data[i], uint(iinput[i])));
        }
        return (vk_x1.X,vk_x1.Y);
    }
}




contract Verifier {
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
      vk.alpha = Pairing.G1Point(uint256(0x24faf4a65c85190f5e99983c694dfb6c951ffbdce4001465379a48865b4a7cad), uint256(0x07d69862c51bfc565518b3b837bfb18eb9d0740681d31bf34502c805313b23d3));
vk.beta = Pairing.G2Point([uint256(0x11e69c91975295e42bc63ace2b21577f55820b1457bca554db947d3cc03de158), uint256(0x16f4d239084c5bfe49750221ba02b5f600f581b8a883ec5697d689dd67f6d784)], [uint256(0x0352e43c51e731816b9880e2fde355488d354d524d5ea638d87994e5a52cc635), uint256(0x2b371a772fa3b35d7c918ea69f084fb939bb08082b2715ff83e9f503906c28dd)]);
vk.gamma = Pairing.G2Point([uint256(0x03e6714513431c44761d74fe7e68b17638b6595759aab0067c6b2dce96430db5), uint256(0x2200f2f9959ca37d2b7086d4877b538b64c9b9a3997566027b5f9685ec57ce1b)], [uint256(0x008debf809a82a1f76cd83e65c991f75029640a6abb06fcab2f546f1e9d70e03), uint256(0x0321969ff4020924cfa5dadf8472cd2b3b344bbecff5ca1f0e43f84ad36471e8)]);
vk.delta = Pairing.G2Point([uint256(0x1590cad18a4bb433289ce1639d455438e5cf534f94641150bd9c32d8c79d7b2f), uint256(0x08946edb34d849da9294948f7994ddb5f3385cf2e4ae6a15fdd99f50a433dc70)], [uint256(0x07363c4090583abc8deec422dec6a3c818c25dd800705022d4ead80877ebb0ac), uint256(0x2d4ec7a5421d10cfc20837989797fd7c852291d9b09fc53f1063905febe229c7)]);
vk.gamma_abc0 = Pairing.G1Point(uint256(0x0451640bbbaac670ae7841671f9b2b689f3385575dac1bf9637430f089336795), uint256(0x29983385efb56e34e9b8e9e24a8efe9008733d6ad30dd4d6ac9700e451508611));
    }
    
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
            uint[2] memory c, uint32[50] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint32[] memory inputValues1 = new uint32[](50);
      
        for(uint i = 0; i < 50; i++){
            inputValues1[i] = input[i];
        }
        
        if (verify(inputValues1,proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}


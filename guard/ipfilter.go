package main

import (
	"fmt"
	"net"
	"net/http"
	"strings"
)

// cidr 统一表示一个 IP 段：单个 IP 会被补成 /32 或 /128。
type cidr struct {
	net *net.IPNet
}

func parseCIDR(s string) (*cidr, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, fmt.Errorf("空的 CIDR")
	}
	if !strings.Contains(s, "/") {
		ip := net.ParseIP(s)
		if ip == nil {
			return nil, fmt.Errorf("非法 IP: %s", s)
		}
		bits := 32
		if ip.To4() == nil {
			bits = 128
		}
		s = s + "/" + fmt.Sprint(bits)
	}
	_, n, err := net.ParseCIDR(s)
	if err != nil {
		return nil, fmt.Errorf("非法 CIDR %s: %w", s, err)
	}
	return &cidr{net: n}, nil
}

func (c *cidr) contains(ip net.IP) bool {
	return c.net.Contains(ip)
}

// matchAny 判断 ip 是否命中列表；空列表返回 false（表示「未限定」由调用方解释）。
func matchAny(list []*cidr, ip net.IP) bool {
	if ip == nil {
		return false
	}
	for _, c := range list {
		if c.contains(ip) {
			return true
		}
	}
	return false
}

func compileCIDRs(list []string) ([]*cidr, error) {
	out := []*cidr{}
	for _, s := range list {
		c, err := parseCIDR(s)
		if err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, nil
}

// clientIP 从常见代理头与 RemoteAddr 里取客户端 IP。
// 路由器场景不经过反向代理，优先信任 RemoteAddr。
func clientIP(r *http.Request) net.IP {
	host := r.RemoteAddr
	if h, _, err := net.SplitHostPort(host); err == nil {
		host = h
	}
	return net.ParseIP(strings.TrimSpace(host))
}

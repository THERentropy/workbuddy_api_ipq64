<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<title>软件中心 - WorkBuddy 网关</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="/res/softcenter.css">
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/validator.js"></script>
<script type="text/javascript" src="/res/softcenter.js"></script>
<style>
:root{
	--wb-bg:#0F1214;
	--wb-card:rgba(37,42,46,.72);
	--wb-card-2:rgba(27,31,34,.9);
	--wb-line:rgba(255,255,255,.10);
	--wb-text:#FFFFFF;
	--wb-text-2:#C7CDD1;
	--wb-text-3:#8A9399;
	--wb-accent:#00B8D9;
	--wb-accent-2:#e82121;
	--wb-ok:#22C55E;
	--wb-err:#EF4444;
	--wb-warn:#F59E0B;
	--wb-info:#3B82F6;
	--wb-radius:14px;
	--wb-a1:rgba(0,184,217,.18);
}
/* 皮肤：安装时按固件类型删除其余三行，只留一条生效 */
:root{--wb-accent:#00B8D9;--wb-a1:rgba(0,184,217,.18);} /* W3C asuscss */
:root{--wb-accent:#e82121;--wb-a1:rgba(232,33,33,.18);} /* W3C rogcss */
:root{--wb-accent:#D0982C;--wb-a1:rgba(208,152,44,.18);} /* W3C tufcss */
:root{--wb-accent:#2ED9C3;--wb-a1:rgba(46,217,195,.18);} /* W3C tscss */
*{-webkit-box-sizing:border-box;box-sizing:border-box;}
body.wb-body{background:var(--wb-bg);color:var(--wb-text);font-family:Roboto-Light,"Microsoft JhengHei",Arial,sans-serif;font-size:13px;}
.wb-wrap{max-width:1180px;margin:0 auto;padding:0 16px 90px 16px;}

/* ---------- 顶部 ---------- */
.wb-hero{position:relative;overflow:hidden;border-radius:var(--wb-radius);padding:20px 22px;margin:16px 0 18px 0;
	background:linear-gradient(135deg,var(--wb-a1) 0%,rgba(15,18,20,.55) 100%);
	border:1px solid var(--wb-line);box-shadow:0 18px 40px rgba(0,0,0,.45);animation:wbFade .5s ease both;}
.wb-hero:before{content:"";position:absolute;width:320px;height:320px;right:-120px;top:-160px;border-radius:50%;
	background:radial-gradient(circle,var(--wb-a1),transparent 65%);pointer-events:none;}
.wb-hero h1{margin:0;font-size:18px;font-weight:600;letter-spacing:.5px;}
.wb-hero .wb-sub{margin-top:6px;color:var(--wb-text-3);font-size:12px;}
.wb-hero-actions{position:absolute;right:18px;top:18px;display:flex;align-items:center;gap:10px;z-index:2;}
.wb-ver{color:var(--wb-text-3);font-size:12px;}

/* ---------- 标签 ---------- */
.wb-tabs{display:flex;gap:6px;flex-wrap:wrap;margin-bottom:16px;border-bottom:1px solid var(--wb-line);padding-bottom:10px;}
.wb-tab{padding:8px 16px;border-radius:999px;cursor:pointer;color:var(--wb-text-3);font-size:13px;font-weight:500;
	border:1px solid transparent;transition:all .22s ease;user-select:none;}
.wb-tab:hover{color:var(--wb-text);background:rgba(255,255,255,.06);}
.wb-tab.active{color:#fff;background:var(--wb-accent);
	border-color:var(--wb-accent);box-shadow:0 6px 18px rgba(0,0,0,.30);}
.wb-panel{display:none;animation:wbUp .35s ease both;}
.wb-panel.active{display:block;}
@keyframes wbFade{from{opacity:0;transform:translateY(-6px);}to{opacity:1;transform:none;}}
@keyframes wbUp{from{opacity:0;transform:translateY(10px);}to{opacity:1;transform:none;}}

/* ---------- 卡片 ---------- */
.wb-card{background:var(--wb-card);border:1px solid var(--wb-line);border-radius:var(--wb-radius);
	padding:16px 18px;margin-bottom:14px;backdrop-filter:blur(8px);-webkit-backdrop-filter:blur(8px);
	box-shadow:0 10px 26px rgba(0,0,0,.32);transition:border-color .25s ease,transform .25s ease;}
.wb-card:hover{border-color:rgba(0,184,217,.35);}
.wb-card h3{margin:0 0 12px 0;font-size:14px;font-weight:500;color:var(--wb-text);display:flex;align-items:center;gap:8px;}
.wb-card h3:before{content:"";width:3px;height:14px;border-radius:2px;background:var(--wb-accent);}
.wb-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px;}
.wb-kpi{background:var(--wb-card-2);border:1px solid var(--wb-line);border-radius:12px;padding:14px 16px;transition:transform .25s ease;}
.wb-kpi:hover{transform:translateY(-3px);}
.wb-kpi .k-label{color:var(--wb-text-3);font-size:12px;}
.wb-kpi .k-value{font-size:24px;font-weight:600;margin-top:6px;letter-spacing:.5px;}
.wb-kpi .k-foot{color:var(--wb-text-3);font-size:11px;margin-top:4px;}

/* ---------- 表格 ---------- */
.wb-table{width:100%;border-collapse:collapse;font-size:12.5px;}
.wb-table th{text-align:left;padding:9px 10px;color:var(--wb-text-3);font-weight:500;border-bottom:1px solid var(--wb-line);white-space:nowrap;}
.wb-table td{padding:9px 10px;border-bottom:1px solid rgba(255,255,255,.05);color:var(--wb-text-2);vertical-align:middle;}
.wb-table tr:hover td{background:rgba(255,255,255,.035);}
.wb-scroll{overflow-x:auto;max-height:420px;overflow-y:auto;}

/* ---------- 徽标 ---------- */
.wb-badge{display:inline-flex;align-items:center;gap:5px;padding:2px 9px;border-radius:999px;font-size:11px;line-height:18px;
	border:1px solid transparent;white-space:nowrap;}
.wb-badge:before{content:"";width:6px;height:6px;border-radius:50%;background:currentColor;}
.b-ok{color:var(--wb-ok);background:rgba(34,197,94,.12);border-color:rgba(34,197,94,.3);}
.b-err{color:var(--wb-err);background:rgba(239,68,68,.12);border-color:rgba(239,68,68,.3);}
.b-warn{color:var(--wb-warn);background:rgba(245,158,11,.12);border-color:rgba(245,158,11,.3);}
.b-info{color:var(--wb-info);background:rgba(59,130,246,.12);border-color:rgba(59,130,246,.3);}
.b-muted{color:var(--wb-text-3);background:rgba(138,147,153,.10);border-color:rgba(138,147,153,.25);}

/* ---------- 进度条 ---------- */
.wb-bar{height:6px;border-radius:999px;background:rgba(255,255,255,.08);overflow:hidden;min-width:80px;}
.wb-bar > i{display:block;height:100%;border-radius:999px;background:linear-gradient(90deg,var(--wb-accent),#22C55E);
	transition:width .5s cubic-bezier(.4,0,.2,1);}

/* ---------- 控件 ---------- */
.wb-btn{border:1px solid var(--wb-line);background:rgba(255,255,255,.06);color:var(--wb-text);
	padding:7px 15px;border-radius:9px;cursor:pointer;font-size:12.5px;transition:all .2s ease;white-space:nowrap;}
.wb-btn:hover{background:rgba(0,184,217,.16);border-color:rgba(0,184,217,.45);transform:translateY(-1px);}
.wb-btn:disabled{opacity:.5;cursor:not-allowed;transform:none;}
.wb-btn.primary{background:var(--wb-accent);border-color:transparent;color:#fff;font-weight:500;}
.wb-btn.primary:hover{box-shadow:0 8px 20px rgba(0,0,0,.32);}
.wb-btn.danger{background:rgba(239,68,68,.14);border-color:rgba(239,68,68,.4);color:#ff8f8f;}
.wb-btn.danger:hover{background:rgba(239,68,68,.24);}
.wb-btn.mini{padding:3px 9px;font-size:11.5px;border-radius:7px;}
.wb-input,.wb-select{background:rgba(0,0,0,.32);border:1px solid var(--wb-line);color:var(--wb-text);
	border-radius:8px;padding:7px 10px;font-size:12.5px;outline:none;transition:border-color .2s ease;width:100%;}
.wb-input:focus,.wb-select:focus{border-color:rgba(0,184,217,.6);}
.wb-row{display:flex;align-items:center;gap:10px;margin-bottom:10px;flex-wrap:wrap;}
.wb-field{display:flex;align-items:center;gap:10px;margin-bottom:12px;}
.wb-field > label{flex:0 0 168px;color:var(--wb-text-3);font-size:12.5px;}
.wb-field .wb-hint{color:var(--wb-text-3);font-size:11px;margin-left:6px;}
.wb-switch{position:relative;display:inline-block;width:44px;height:24px;flex:0 0 auto;}
.wb-switch input{display:none;}
.wb-switch i{position:absolute;inset:0;background:rgba(255,255,255,.14);border-radius:999px;transition:background .25s ease;cursor:pointer;}
.wb-switch i:before{content:"";position:absolute;width:18px;height:18px;left:3px;top:3px;background:#fff;border-radius:50%;transition:transform .25s cubic-bezier(.4,0,.2,1);}
.wb-switch input:checked + i{background:var(--wb-accent);}
.wb-switch input:checked + i:before{transform:translateX(20px);}

/* ---------- 弹层 ---------- */
.wb-mask{position:fixed;inset:0;background:rgba(0,0,0,.62);z-index:200;display:none;align-items:center;justify-content:center;}
.wb-mask.show{display:flex;animation:wbFade .2s ease both;}
.wb-modal{width:520px;max-width:92vw;max-height:84vh;overflow:auto;background:#1B1F22;border:1px solid var(--wb-line);
	border-radius:16px;padding:18px 20px;box-shadow:0 24px 60px rgba(0,0,0,.6);animation:wbUp .28s ease both;}
.wb-modal h4{margin:0 0 14px 0;font-size:15px;font-weight:600;}
.wb-modal .wb-modal-foot{display:flex;justify-content:flex-end;gap:10px;margin-top:16px;}
.wb-code{background:rgba(0,0,0,.45);border:1px dashed rgba(0,184,217,.45);border-radius:10px;padding:12px;
	word-break:break-all;font-family:'Lucida Console',Consolas,monospace;font-size:12px;color:#9fe8f5;margin:10px 0;}

/* ---------- 提示气泡 ---------- */
.wb-toast{position:fixed;top:18px;left:50%;transform:translateX(-50%);z-index:300;display:none;
	padding:10px 18px;border-radius:10px;background:#1B1F22;border:1px solid var(--wb-line);font-size:12.5px;
	box-shadow:0 12px 30px rgba(0,0,0,.5);animation:wbUp .25s ease both;max-width:80vw;}
.wb-toast.ok{border-color:rgba(34,197,94,.5);color:#8ef0b0;}
.wb-toast.err{border-color:rgba(239,68,68,.5);color:#ffabab;}
.wb-toast.info{border-color:rgba(0,184,217,.5);color:#9fe8f5;}

/* ---------- 步骤条 ---------- */
.wb-steps{display:flex;gap:8px;margin:6px 0 14px 0;}
.wb-step{flex:1;text-align:center;padding:8px 6px;border-radius:9px;font-size:11.5px;color:var(--wb-text-3);
	background:rgba(255,255,255,.05);border:1px solid transparent;transition:all .25s ease;}
.wb-step.on{color:#fff;border-color:rgba(0,184,217,.5);background:rgba(0,184,217,.16);}
.wb-step.done{color:#8ef0b0;border-color:rgba(34,197,94,.45);background:rgba(34,197,94,.12);}

.wb-empty{padding:26px;text-align:center;color:var(--wb-text-3);font-size:12.5px;}
.wb-mono{font-family:'Lucida Console',Consolas,monospace;font-size:11.5px;}
.wb-note{color:var(--wb-text-3);font-size:11.5px;line-height:1.7;}
.wb-logbox{background:rgba(0,0,0,.4);border:1px solid var(--wb-line);border-radius:10px;padding:10px;
	max-height:220px;overflow:auto;white-space:pre-wrap;font-family:'Lucida Console',Consolas,monospace;
	font-size:11px;color:#a8b3b8;line-height:1.55;}
.wb-inline{display:flex;gap:10px;align-items:center;flex-wrap:wrap;}
@media (max-width:720px){
	.wb-wrap{padding:0 10px 80px 10px;}
	.wb-field{flex-direction:column;align-items:flex-start;gap:5px;}
	.wb-field > label{flex:none;}
	.wb-hero-actions{position:static;margin-top:12px;}
	.wb-table,.wb-table tbody,.wb-table tr,.wb-table td{display:block;width:100%;}
	.wb-table thead{display:none;}
	.wb-table tr{margin-bottom:10px;border:1px solid var(--wb-line);border-radius:10px;padding:8px;}
	.wb-table td{border:none;padding:5px 8px;}
	.wb-table td:before{content:attr(data-l);color:var(--wb-text-3);display:inline-block;min-width:88px;}
}
</style>
</head>
<body class="wb-body">
<div class="wb-wrap">

	<div class="wb-hero">
		<h1>WorkBuddy 网关 <span class="wb-ver" id="wb_version"></span></h1>
		<div class="wb-sub">CodeBuddy 账号池 → OpenAI 兼容 API · 多密钥分发 · 调用审计</div>
		<div class="wb-hero-actions">
			<label class="wb-switch" title="启用插件">
				<input type="checkbox" id="workbuddy_enable"><i></i>
			</label>
			<button class="wb-btn primary" id="wb_btn_start">启动</button>
			<button class="wb-btn" id="wb_btn_stop">停止</button>
			<button class="wb-btn" id="wb_btn_restart">重启</button>
		</div>
	</div>

	<div class="wb-tabs">
		<div class="wb-tab active" data-p="p_status">状态总览</div>
		<div class="wb-tab" data-p="p_account">账号池</div>
		<div class="wb-tab" data-p="p_key">密钥管理</div>
		<div class="wb-tab" data-p="p_log">统计与日志</div>
		<div class="wb-tab" data-p="p_set">设置</div>
	</div>

	<!-- ============ 状态总览 ============ -->
	<div class="wb-panel active" id="p_status">
		<div class="wb-grid">
			<div class="wb-kpi"><div class="k-label">服务状态</div><div class="k-value" id="kpi_service">-</div><div class="k-foot" id="kpi_service_foot">读取中…</div></div>
			<div class="wb-kpi"><div class="k-label">健康账号 / 总数</div><div class="k-value" id="kpi_account">-</div><div class="k-foot" id="kpi_account_foot">冷却中 0 · 已禁用 0</div></div>
			<div class="wb-kpi"><div class="k-label">今日调用</div><div class="k-value" id="kpi_calls">-</div><div class="k-foot" id="kpi_calls_foot">成功率 -</div></div>
			<div class="wb-kpi"><div class="k-label">近 7 日消耗积分</div><div class="k-value" id="kpi_credit">-</div><div class="k-foot" id="kpi_credit_foot">来自上游 usage.credit</div></div>
		</div>

		<div class="wb-card">
			<h3>运行信息</h3>
			<table class="wb-table"><tbody id="runtime_tb">
				<tr><td>监听地址（对外）</td><td id="rt_listen">-</td></tr>
				<tr><td>上游网关</td><td id="rt_upstream">-</td></tr>
				<tr><td>进程 PID</td><td id="rt_pid">-</td></tr>
				<tr><td>数据目录</td><td id="rt_data">-</td></tr>
				<tr><td>开机自启 / 看门狗</td><td id="rt_auto">-</td></tr>
				<tr><td>外网放行</td><td id="rt_wan">-</td></tr>
			</tbody></table>
			<div class="wb-note" style="margin-top:10px">
				下游客户端请使用「对外端口 + 分发密钥」访问，例如 <span class="wb-mono">http://路由器IP:17863/v1/chat/completions</span>；上游网关只绑定 127.0.0.1，不直接暴露。
			</div>
		</div>

		<div class="wb-card">
			<h3>通道诊断
				<span class="wb-inline" style="margin-left:auto"><button class="wb-btn mini" id="wb_btn_diag">重新检测</button></span>
			</h3>
			<table class="wb-table"><tbody>
				<tr><td>POST /_api/（执行脚本）</td><td id="dg_post">-</td></tr>
				<tr><td>结果文件 /_temp/</td><td id="dg_file">-</td></tr>
				<tr><td>dbus 回传通道</td><td id="dg_dbus">-</td></tr>
				<tr><td>脚本名（必须与 /koolshare/scripts/ 下文件名一致）</td><td id="dg_scripts" class="wb-mono">-</td></tr>
			</tbody></table>
			<div class="wb-note" style="margin-top:10px">
				「POST」红色 = 软件中心没执行脚本（method 名与脚本文件名不一致时会静默失败）；
				「结果文件」红色 = httpd 的 <span class="wb-mono">/_temp/</span> 没映射到 <span class="wb-mono">/tmp/upload/</span>。
			</div>
		</div>
	</div>

	<!-- ============ 账号池 ============ -->
	<div class="wb-panel" id="p_account">
		<div class="wb-card">
			<h3>账号池
				<span class="wb-inline" style="margin-left:auto">
					<button class="wb-btn mini" id="wb_btn_add_account">添加账号</button>
					<button class="wb-btn mini" id="wb_btn_signin">手动签到</button>
					<button class="wb-btn mini" id="wb_btn_refresh_account">刷新</button>
				</span>
			</h3>
			<div class="wb-scroll">
				<table class="wb-table">
					<thead><tr><th>昵称 / UID</th><th>域</th><th>状态</th><th>积分</th><th>有效期</th><th>在途</th><th>操作</th></tr></thead>
					<tbody id="account_tb"></tbody>
				</table>
			</div>
			<div class="wb-empty" id="account_empty">暂无账号，点右上角「添加账号」扫码纳管</div>
		</div>
		<div class="wb-card">
			<h3>可用模型</h3>
			<div class="wb-inline" id="model_box"><span class="wb-note">点击右侧按钮从上游拉取</span></div>
			<div style="margin-top:10px"><button class="wb-btn mini" id="wb_btn_models">拉取模型列表</button></div>
		</div>
	</div>

	<!-- ============ 密钥管理 ============ -->
	<div class="wb-panel" id="p_key">
		<div class="wb-card">
			<h3>分发密钥
				<span class="wb-inline" style="margin-left:auto">
					<button class="wb-btn mini primary" id="wb_btn_add_key">新建密钥</button>
					<button class="wb-btn mini" id="wb_btn_policy">IP 策略</button>
					<button class="wb-btn mini" id="wb_btn_refresh_key">刷新</button>
				</span>
			</h3>
			<div class="wb-note" style="margin-bottom:10px">库中仅保存 SHA-256，明文只在创建时展示一次。上游只有一个全局 api_key，多密钥配额由本插件的代理层实现。</div>
			<div class="wb-scroll">
				<table class="wb-table">
					<thead><tr><th>名称 / 前缀</th><th>状态</th><th>有效期</th><th>配额用量</th><th>限制</th><th>最近使用</th><th>操作</th></tr></thead>
					<tbody id="key_tb"></tbody>
				</table>
			</div>
			<div class="wb-empty" id="key_empty">暂无密钥，点「新建密钥」创建第一把</div>
		</div>
	</div>

	<!-- ============ 统计与日志 ============ -->
	<div class="wb-panel" id="p_log">
		<div class="wb-card">
			<h3>调用统计
				<span class="wb-inline" style="margin-left:auto">
					<select class="wb-select" id="stat_days" style="width:120px">
						<option value="1">今天</option><option value="7" selected>近 7 日</option><option value="30">近 30 日</option>
					</select>
					<button class="wb-btn mini" id="wb_btn_stat">刷新</button>
				</span>
			</h3>
			<div class="wb-grid" id="stat_grid"></div>
			<div class="wb-grid" style="margin-top:12px" id="stat_top"></div>
		</div>

		<div class="wb-card">
			<h3>调用日志
				<span class="wb-inline" style="margin-left:auto">
					<select class="wb-select" id="log_days" style="width:100px"><option value="1">1天</option><option value="2" selected>2天</option><option value="7">7天</option></select>
					<select class="wb-select" id="log_n" style="width:110px"><option value="100">100 条</option><option value="200" selected>200 条</option><option value="500">500 条</option></select>
					<label class="wb-note"><input type="checkbox" id="log_err"> 仅失败</label>
					<button class="wb-btn mini" id="wb_btn_log">刷新</button>
					<button class="wb-btn mini danger" id="wb_btn_log_clean">清理过期</button>
				</span>
			</h3>
			<div class="wb-scroll">
				<table class="wb-table">
					<thead><tr><th>时间</th><th>密钥</th><th>来源 IP</th><th>模型</th><th>状态</th><th>首字</th><th>耗时</th><th>Token</th><th>积分</th></tr></thead>
					<tbody id="log_tb"></tbody>
				</table>
			</div>
			<div class="wb-empty" id="log_empty">暂无调用记录</div>
		</div>

		<div class="wb-card">
			<h3>服务日志<button class="wb-btn mini" id="wb_btn_slog" style="margin-left:auto">刷新</button></h3>
			<div class="wb-logbox" id="servicelog">点击刷新查看</div>
		</div>
	</div>

	<!-- ============ 设置 ============ -->
	<div class="wb-panel" id="p_set">
		<div class="wb-card">
			<h3>服务</h3>
			<div class="wb-field"><label>对外监听端口</label><input class="wb-input" id="workbuddy_listen_port" style="max-width:160px" type="text"><span class="wb-hint">1-65535</span></div>
			<div class="wb-field"><label>上游网关端口</label><input class="wb-input" id="workbuddy_upstream_port" style="max-width:160px" type="text"><span class="wb-hint">固定绑定 127.0.0.1</span></div>
			<div class="wb-field"><label>上游 API Key</label><input class="wb-input" id="workbuddy_api_key" style="max-width:320px" type="text"><span class="wb-hint">上游全局密钥，留空=不鉴权</span></div>
			<div class="wb-field"><label>开机自启</label><label class="wb-switch"><input type="checkbox" id="workbuddy_auto_start"><i></i></label></div>
			<div class="wb-field"><label>放行外网访问</label><label class="wb-switch"><input type="checkbox" id="workbuddy_wan"><i></i></label><span class="wb-hint">默认仅 LAN，开启会把端口暴露到 WAN</span></div>
			<div class="wb-field"><label>看门狗（5 分钟）</label><label class="wb-switch"><input type="checkbox" id="workbuddy_watchdog"><i></i></label></div>
			<div class="wb-field"><label>自动配置防火墙</label><label class="wb-switch"><input type="checkbox" id="workbuddy_firewall"><i></i></label></div>
		</div>

		<div class="wb-card">
			<h3>数据存放</h3>
			<div class="wb-field"><label>数据目录</label><input class="wb-input" id="workbuddy_data_dir" style="max-width:340px" type="text"></div>
			<div class="wb-field"><label>审计日志保留天数</label><input class="wb-input" id="workbuddy_audit_days" style="max-width:120px" type="text"></div>
			<div class="wb-field"><label>单日志文件上限(MB)</label><input class="wb-input" id="workbuddy_audit_max_mb" style="max-width:120px" type="text"></div>
			<div class="wb-inline">
				<button class="wb-btn" id="wb_btn_migrate">迁移到该目录</button>
				<span class="wb-note">凭证 / 密钥 / 审计日志会整体搬迁，建议插 U 盘后改到 /tmp/mnt/xxx 减少闪存写入</span>
			</div>
		</div>

		<div class="wb-card">
			<h3>定时任务（整点，0-23，逗号分隔）</h3>
			<div class="wb-field"><label>签到</label><label class="wb-switch"><input type="checkbox" id="workbuddy_checkin_enabled"><i></i></label><input class="wb-input" id="workbuddy_checkin_hours" style="max-width:140px" type="text"></div>
			<div class="wb-field"><label>猫猫旅行</label><label class="wb-switch"><input type="checkbox" id="workbuddy_travel_enabled"><i></i></label><input class="wb-input" id="workbuddy_travel_hours" style="max-width:140px" type="text"></div>
			<div class="wb-field"><label>活跃上报</label><label class="wb-switch"><input type="checkbox" id="workbuddy_activity_enabled"><i></i></label><input class="wb-input" id="workbuddy_activity_hours" style="max-width:140px" type="text"></div>
			<div class="wb-field"><label>Token 保活</label><label class="wb-switch"><input type="checkbox" id="workbuddy_keepalive_enabled"><i></i></label><input class="wb-input" id="workbuddy_keepalive_hours" style="max-width:140px" type="text"></div>
			<div class="wb-field"><label>开学季任务</label><label class="wb-switch"><input type="checkbox" id="workbuddy_school_enabled"><i></i></label><input class="wb-input" id="workbuddy_school_hours" style="max-width:140px" type="text"></div>
			<div class="wb-field"><label>夜猫子任务</label><label class="wb-switch"><input type="checkbox" id="workbuddy_cat_enabled"><i></i></label><input class="wb-input" id="workbuddy_cat_hours" style="max-width:140px" type="text"></div>
		</div>

		<div class="wb-card">
			<h3>账号池与流控</h3>
			<div class="wb-field"><label>单账号最大在途</label><input class="wb-input" id="workbuddy_max_in_flight" style="max-width:120px" type="text"></div>
			<div class="wb-field"><label>熔断阈值（连续失败）</label><input class="wb-input" id="workbuddy_breaker_threshold" style="max-width:120px" type="text"></div>
			<div class="wb-field"><label>熔断冷却 / 封顶</label><input class="wb-input" id="workbuddy_breaker_cooldown" style="max-width:110px" type="text"><input class="wb-input" id="workbuddy_breaker_cooldown_max" style="max-width:110px" type="text"></div>
			<div class="wb-field"><label>软限流冷却 / 上限</label><input class="wb-input" id="workbuddy_soft_rate" style="max-width:110px" type="text"><input class="wb-input" id="workbuddy_soft_rate_max" style="max-width:110px" type="text"></div>
			<div class="wb-field"><label>快过期积分窗口</label><input class="wb-input" id="workbuddy_expiring_soon" style="max-width:120px" type="text"><span class="wb-hint">0 关闭</span></div>
			<div class="wb-field"><label>会话粘性</label><label class="wb-switch"><input type="checkbox" id="workbuddy_sticky"><i></i></label><input class="wb-input" id="workbuddy_sticky_ttl" style="max-width:110px" type="text"></div>
			<div class="wb-field"><label>指纹脱敏</label><label class="wb-switch"><input type="checkbox" id="workbuddy_sanitize"><i></i></label></div>
			<div class="wb-field"><label>国际版支持</label><label class="wb-switch"><input type="checkbox" id="workbuddy_global_enabled"><i></i></label></div>
			<div class="wb-field"><label>上游超时（秒）</label><input class="wb-input" id="workbuddy_timeout" style="max-width:120px" type="text"></div>
			<div class="wb-field"><label>提示词模式</label>
				<select class="wb-select" id="workbuddy_prompt_mode" style="max-width:200px">
					<option value="passthrough">passthrough（透传客户端）</option>
					<option value="custom">custom（网关替换）</option>
				</select>
			</div>
		</div>

		<div class="wb-inline" style="margin-bottom:10px">
			<button class="wb-btn primary" id="wb_btn_save">保存并应用</button>
			<span class="wb-note">保存后会重新渲染上游配置并重启服务</span>
		</div>
		<div class="wb-note" style="margin-bottom:30px">
			<b>卸载提示：</b>软件中心要求插件处于「已关闭」状态才能卸载。请先拨掉页面右上角的开关（拨动即生效，无需再点保存），
			再回软件中心执行卸载。数据目录会保留，如需一并删除请先手动 <span class="wb-mono">rm -rf</span>。
		</div>
	</div>

	<div class="wb-note" style="margin:18px 0 0 0;padding-bottom:20px">
		合规提示：本插件为非官方网关，仅限本人授权账号、私有环境使用；请勿共享、转售或用于违反上游平台服务条款的用途。
	</div>
</div>

<div class="wb-toast" id="wb_toast"></div>
<div class="wb-mask" id="wb_mask"><div class="wb-modal" id="wb_modal"></div></div>

<script>
/* ============================================================================
 * WorkBuddy 网关 —— 页面脚本
 *
 * 与软件中心交互只有两条通道，别再引入第三种：
 *   1) POST /_api/            执行 /koolshare/scripts/<method>
 *      ★ 关键：method 必须等于脚本的真实文件名（带 .sh）。
 *        写成 "workbuddy_status" 时，中心会去找
 *        /koolshare/scripts/workbuddy_status —— 这个文件不存在，
 *        于是它静默返回、什么都不执行，页面表现就是"点了没反应"。
 *        官方插件同理：kms_config.sh、entware_status.sh 都是带扩展名的。
 *   2) GET /_temp/<file>      读脚本写在 /tmp/upload/ 下的结果文件
 *
 * 动作是异步的，所以流程是：POST 提交 → 轮询结果文件 → 拿不到就退到 dbus。
 * ============================================================================ */
var S = {
	status:  "workbuddy_status.sh",
	account: "workbuddy_account.sh",
	key:     "workbuddy_key.sh",
	log:     "workbuddy_log.sh",
	migrate: "workbuddy_migrate.sh",
	config:  "workbuddy_config.sh"
};

var CACHE = { status: null, auths: null, dbus: {} };
var DIAG  = { post: null, file: null, dbus: null };
var BUSY  = false;

/* ============================ 基础工具 ============================ */
function esc(s){
	return String(s === undefined || s === null ? "" : s)
		.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
function p2(n){ return (n < 10 ? "0" : "") + n; }
function ts(t){
	if(!t) return "-";
	var d = new Date(t * 1000);
	return d.getFullYear() + "-" + p2(d.getMonth() + 1) + "-" + p2(d.getDate()) + " " + p2(d.getHours()) + ":" + p2(d.getMinutes()) + ":" + p2(d.getSeconds());
}
function ago(t){
	if(!t) return "从未";
	var s = Math.floor(new Date().getTime() / 1000) - t;
	if(s < 60) return s + " 秒前";
	if(s < 3600) return Math.floor(s / 60) + " 分钟前";
	if(s < 86400) return Math.floor(s / 3600) + " 小时前";
	return Math.floor(s / 86400) + " 天前";
}
function toast(msg, type){
	var t = $("#wb_toast");
	t.removeClass("ok err info").addClass(type || "info").text(msg).show();
	clearTimeout(t.data("timer"));
	t.data("timer", setTimeout(function(){ t.fadeOut(200); }, type === "err" ? 5000 : 2600));
}
function modal(html){ $("#wb_modal").html(html); $("#wb_mask").addClass("show"); }
function closeModal(){ $("#wb_mask").removeClass("show"); }
function badge(text, cls){ return '<span class="wb-badge ' + cls + '">' + esc(text) + "</span>"; }
function setBadge(sel, v, okText, badText){
	if(v === true){ $(sel).html(badge(okText, "b-ok")); }
	else if(v === false){ $(sel).html(badge(badText, "b-err")); }
	else { $(sel).html('<span class="wb-note">未检测</span>'); }
}
function chkVal(id){ return $("#" + id).prop("checked") ? "1" : "0"; }
function setChk(id, v){ $("#" + id).prop("checked", (v === "1" || v === 1 || v === true)); }

/* ============================ 通道层 ============================ */
// POST /_api/：脚本执行完会回 {"result": <我们发去的 id>}
// ★ 这里刻意不用 dataType:"json"：脚本的输出可能夹带别的行（日志、路径等），
//   整体不是合法 JSON 时 jQuery 会走 error 回调，把已经成功的动作误判为失败。
//   所以按文本收，再宽松解析；解析不出来也不下结论，交给结果文件判断。
function post(script, params, fields, cb){
	var id = Math.floor(Math.random() * 100000000);
	var body = { "id": id, "method": script, "params": params || [""], "fields": fields || {} };
	$.ajax({
		type: "POST", url: "/_api/", dataType: "text", cache: false,
		data: JSON.stringify(body), timeout: 300000,
		success: function(txt){
			var r = null;
			try{ r = JSON.parse($.trim(txt)); }
			catch(e){
				var m = String(txt).match(/\{\s*"result"\s*:\s*(-?\d+)\s*\}/);
				if(m){ try{ r = JSON.parse(m[0]); }catch(e2){} }
			}
			if(r && String(r.result) === "-403"){
				DIAG.post = false;
				cb("会话失效（/_api/ 返回 -403），请重新登录路由器后再试");
				return;
			}
			// ★ 必须比字符串：httpd 回的是 {"result": "246810"}（带引号的字符串），
			//   id 是数字，用 === 严格比较永远为假，会把成功判成失败。
			DIAG.post = r ? (String(r.result) === String(id)) : null;
			cb(null);
		},
		error: function(xhr){ DIAG.post = false; cb("提交失败：HTTP " + (xhr && xhr.status ? xhr.status : "超时")); }
	});
}

// GET 结果文件：404 说明"通道正常、文件还没生成"，其它错误才算通道不通
function fetchFile(name, cb){
	$.ajax({
		type: "GET", url: "/_temp/" + name, dataType: "json", cache: false, timeout: 20000,
		success: function(d){ DIAG.file = true; cb(d); },
		error: function(x){
			if(x && x.status === 404){ DIAG.file = true; cb(null); return; }
			$.ajax({
				type: "GET", url: "/tmp/" + name, dataType: "json", cache: false, timeout: 20000,
				success: function(d){ DIAG.file = true; cb(d); },
				error: function(x2){ DIAG.file = (x2 && x2.status === 404); cb(null); }
			});
		}
	});
}

function getDbus(cb){
	$.ajax({
		type: "GET", url: "/_api/workbuddy", dataType: "json", cache: false, timeout: 15000,
		success: function(d){
			CACHE.dbus = (d && d.result && d.result[0]) ? d.result[0] : {};
			DIAG.dbus = true;
			cb(CACHE.dbus);
		},
		error: function(){ DIAG.dbus = false; cb({}); }
	});
}

// 动作：提交 → 轮询结果（脚本只在结束时写一次结果，且开始前已清空）
function run(script, params, fields, outFile, cb){
	post(script, params, fields, function(perr){
		if(perr){ cb({ ok: false, err: perr }); return; }
		var tries = 0, max = 60;
		function next(){
			if(tries < max){ setTimeout(step, 1000); }
			else { cb({ ok: false, err: "等待结果超时（" + max + " 秒），请重试或查看服务日志" }); }
		}
		function step(){
			tries++;
			fetchFile(outFile, function(d){
				if(d && (d.ok || d.err)){ cb(d); return; }
				if(DIAG.file === false){
					// 文件通道不通，用 dbus 兜底（脚本同时写了一份）
					getDbus(function(m){
						var s = m && m.workbuddy_last_result;
						if(s){
							try{
								var o = JSON.parse(s);
								if(o && (o.ok || o.err)){ cb(o); return; }
							}catch(e){}
						}
						next();
					});
					return;
				}
				next();
			});
		}
		step();
	});
}

/* ============================ 诊断面板 ============================ */
function renderDiag(){
	setBadge("#dg_post", DIAG.post, "/_api/ 正常，脚本已执行", "未执行脚本（检查 method 名）");
	setBadge("#dg_file", DIAG.file, "/_temp/ 正常（→ /tmp/upload/）", "取不到结果文件");
	setBadge("#dg_dbus", DIAG.dbus, "dbus 回传正常", "dbus 不可用");
	$("#dg_scripts").text(S.status + " · " + S.account + " · " + S.key);
}

/* ============================ 状态总览 ============================ */
function loadStatus(quiet){
	run(S.status, [""], {}, "workbuddy_status.json", function(d){
		renderStatus(d);
		renderDiag();
		if(!quiet && d && !d.ok){ toast(d.err || "状态读取失败", "err"); }
	});
}
function renderStatus(d){
	if(!d || !d.ok){
		$("#kpi_service").html(badge("读取失败", "b-err"));
		$("#kpi_service_foot").text((d && d.err) || "无返回");
		$("#kpi_account").text("-"); $("#kpi_account_foot").text("-");
		CACHE.status = null;
		renderAccounts();
		return;
	}
	if(!d.running){
		$("#kpi_service").html(badge("未运行", "b-err"));
		$("#kpi_service_foot").text(d.err ? String(d.err).slice(0, 60) : "上游网关未就绪");
		$("#kpi_account").text("-"); $("#kpi_account_foot").text("-");
		CACHE.status = null;
		renderAccounts();
		return;
	}
	CACHE.status = d;
	$("#kpi_service").html(badge("运行中", "b-ok"));
	$("#kpi_service_foot").text("账号 " + (d.total || 0) + " 个 · 会话粘性 " + (d.sticky_sessions || 0));
	$("#kpi_account").text((d.healthy || 0) + " / " + (d.total || 0));
	$("#kpi_account_foot").text("冷却中 " + (d.cooling || 0) + " · 已禁用 " + (d.disabled || 0));
	renderAccounts();
}
function loadRuntime(){
	fetchFile("workbuddy_runtime.json", function(d){
		if(!d || !d.ok) return;
		$("#rt_listen").text(":" + d.listen_port + "（对外）");
		$("#rt_upstream").text("127.0.0.1:" + d.upstream_port);
		$("#rt_pid").text("网关 " + (d.upstream_pid || "-") + " · 代理 " + (d.ctl_pid || "-"));
		$("#rt_data").text(d.data_dir);
		$("#rt_auto").text((d.auto_start === "1" ? "开" : "关") + " / 看门狗 " + (d.watchdog === "1" ? "开" : "关"));
		$("#rt_wan").html(d.wan === "1" ? badge("已放行 WAN", "b-warn") : badge("仅 LAN", "b-ok"));
		$("#wb_version").text("v" + (d.version || ""));
	});
}

/* ============================ 账号池 ============================ */
// 以「凭证文件」为准渲染（服务没起来也能看到账号），上游运行态有就合并进来
function loadAccounts(){
	run(S.account, ["list"], {}, "workbuddy_accounts.json", function(a){
		if(a && a.ok && a.accounts){ CACHE.auths = a.accounts; }
		else if(a && a.err){ toast("读取账号失败：" + a.err, "err"); }
		renderAccounts();
	});
	loadStatus(true);
	loadRuntime();
}
function renderAccounts(){
	var auths = CACHE.auths || [];
	var st = CACHE.status;
	var byUid = {};
	if(st && st.accounts){
		for(var i = 0; i < st.accounts.length; i++){ byUid[st.accounts[i].uid] = st.accounts[i]; }
	}
	// 合并两侧的 uid：凭证为准，上游独有的也补上（例如手动放进 auths 的）
	var rows = [], seen = {};
	for(var j = 0; j < auths.length; j++){
		var u = auths[j].uid;
		seen[u] = true;
		rows.push({ cred: auths[j], rt: byUid[u] || null });
	}
	for(var k in byUid){
		if(!seen[k]){ rows.push({ cred: null, rt: byUid[k] }); }
	}

	var html = "";
	for(var n = 0; n < rows.length; n++){
		var c = rows[n].cred, r = rows[n].rt;
		var uid = (c && c.uid) || (r && r.uid) || "";
		var nick = (r && r.nickname) || (c && c.nickname) || ("UID " + uid);
		var realm = (r && r.realm) || (c && c.realm) || "cn";

		var state;
		if(r){
			if(r.disabled) state = badge("已禁用", "b-err");
			else if(r.cooling) state = badge("冷却中", "b-warn");
			else state = badge("健康", "b-ok");
			if(r.reason) state += '<div class="wb-note">' + esc(r.reason) + '</div>';
		}else{
			state = badge("服务未运行", "b-muted");
		}

		// 有效期：优先用凭证里的 expires_at
		var exp = c ? c.expires_at : 0;
		var pct = 0, txt = "未知";
		if(exp){
			var left = exp - Math.floor(new Date().getTime() / 1000);
			pct = Math.max(0, Math.min(100, Math.round(left / (60 * 24 * 3600) * 100)));
			txt = left > 0 ? (Math.floor(left / 86400) + " 天") : "已过期";
		}
		var credit = r && r.credits !== undefined ? r.credits : "-";

		html += "<tr>"
			+ '<td data-l="账号">' + esc(nick) + '<div class="wb-note wb-mono">' + esc(uid) + '</div></td>'
			+ '<td data-l="域">' + (realm === "global" ? badge("国际版", "b-info") : badge("国内版", "b-muted")) + '</td>'
			+ '<td data-l="状态">' + state + '</td>'
			+ '<td data-l="积分">' + credit + '</td>'
			+ '<td data-l="有效期"><div class="wb-bar"><i style="width:' + pct + '%"></i></div><div class="wb-note">' + txt + '</div></td>'
			+ '<td data-l="在途">' + (r ? (r.in_flight || 0) : "-") + '</td>'
			+ '<td data-l="操作"><button class="wb-btn mini danger" onclick="removeAccount(\'' + esc(uid) + '\')">删除</button></td>'
			+ "</tr>";
	}
	$("#account_tb").html(html);
	$("#account_empty").toggle(rows.length === 0);
}
function removeAccount(uid){
	if(!uid){ toast("没有 uid，无法删除", "err"); return; }
	if(!confirm("确认删除账号 " + uid + " 的凭证？删除后该账号立即退出池子。")) return;
	run(S.account, ["remove", "--uid=" + uid], {}, "workbuddy_action.json", function(d){
		toast(d.ok ? "已删除" : ("删除失败：" + (d.err || "")), d.ok ? "ok" : "err");
		if(d.ok) setTimeout(loadAccounts, 1500);
	});
}

/* 添加账号：三步引导，全程一个 state，别中途再点「获取授权链接」 */
$("#wb_btn_add_account").click(function(){
	modal('<h4>添加账号</h4>'
		+ '<div class="wb-steps"><div class="wb-step on" id="st1">1. 取授权链接</div><div class="wb-step" id="st2">2. 浏览器登录</div><div class="wb-step" id="st3">3. 完成</div></div>'
		+ '<div class="wb-field"><label>域</label><select class="wb-select" id="lg_realm" style="max-width:220px">'
		+ '<option value="cn">国内版（copilot.tencent.com）</option><option value="global">国际版（workbuddy.ai）</option></select></div>'
		+ '<div id="lg_box"><button class="wb-btn primary" id="lg_url">获取授权链接</button></div>'
		+ '<div class="wb-modal-foot"><button class="wb-btn" onclick="closeModal()">关闭</button></div>');

	$("#lg_url").click(function(){
		var realm = $("#lg_realm").val();
		var $b = $(this).prop("disabled", true).text("获取中…");
		run(S.account, ["url", "--realm=" + realm], {}, "workbuddy_login_url.json", function(d){
			if(!d.ok){
				$b.prop("disabled", false).text("重试");
				$("#lg_box").append('<div style="margin-top:10px">' + badge(d.err || "获取失败", "b-err") + "</div>");
				return;
			}
			$("#st1").removeClass("on").addClass("done"); $("#st2").addClass("on");
			$("#lg_box").html('<div class="wb-note">在浏览器打开下面的链接完成登录。'
				+ '<b>登录完成前不要再点上面的按钮</b>，否则腾讯那边的待授权会话会被新的顶掉。</div>'
				+ '<div class="wb-code" id="lg_url_text">' + esc(d.url) + "</div>"
				+ '<div class="wb-inline"><button class="wb-btn" onclick="copyText(\'lg_url_text\')">复制链接</button>'
				+ '<a class="wb-btn primary" target="_blank" href="' + esc(d.url) + '">打开链接</a></div>'
				+ '<div class="wb-inline" style="margin-top:14px"><button class="wb-btn primary" id="lg_poll">我已完成登录</button></div>');
			$("#lg_poll").click(function(){
				var $p = $(this).prop("disabled", true);
				var t0 = new Date().getTime();
				$p.text("轮询中… 0s");
				var tm = setInterval(function(){
					$p.text("轮询中… " + Math.round((new Date().getTime() - t0) / 1000) + "s");
				}, 1000);
				run(S.account, ["poll", "--realm=" + realm], {}, "workbuddy_login_poll.json", function(r){
					clearInterval(tm);
					if(!r.ok){
						$("#lg_box").append('<div style="margin-top:10px">' + badge(r.err || "登录未完成", "b-err") + "</div>");
						$p.prop("disabled", false).text("重试");
						return;
					}
					$("#st2").removeClass("on").addClass("done"); $("#st3").addClass("done");
					$("#lg_box").html('<div style="text-align:center;padding:10px 0">'
						+ '<div style="font-size:30px">🎉</div>'
						+ '<div style="margin:8px 0">账号已纳管（' + esc(r.action || "新增") + '）</div>'
						+ '<div class="wb-note">' + esc(r.nickname || r.uid || "") + "</div></div>");
					setTimeout(function(){ closeModal(); loadAccounts(); }, 1500);
				});
			});
		});
	});
});
function copyText(id){
	var el = document.getElementById(id);
	if(!el) return;
	var ta = document.createElement("textarea");
	ta.value = el.textContent || el.innerText;
	document.body.appendChild(ta);
	ta.select();
	try{ document.execCommand("copy"); toast("已复制", "ok"); }
	catch(e){ toast("复制失败，请手动选择", "err"); }
	document.body.removeChild(ta);
}

$("#wb_btn_signin").click(function(){
	var $b = $(this).prop("disabled", true).text("签到中…");
	run(S.account, ["signin"], {}, "workbuddy_action.json", function(d){
		$b.prop("disabled", false).text("手动签到");
		if(!d.ok){ toast("签到失败：" + (d.err || ""), "err"); return; }
		var out = d.output || "签到完成";
		modal("<h4>签到结果</h4><div class='wb-logbox'>" + esc(out) + "</div>"
			+ '<div class="wb-modal-foot"><button class="wb-btn" onclick="closeModal()">关闭</button></div>');
	});
});
$("#wb_btn_refresh_account").click(loadAccounts);
$("#wb_btn_models").click(function(){
	var $b = $(this).prop("disabled", true).text("拉取中…");
	run(S.status, ["models"], {}, "workbuddy_models.json", function(d){
		$b.prop("disabled", false).text("拉取模型列表");
		var ids = [];
		if(d && d.ok && d.raw && d.raw.data){
			for(var i = 0; i < d.raw.data.length; i++){ ids.push(d.raw.data[i].id); }
		}
		if(!ids.length){ $("#model_box").html('<span class="wb-note">没取到模型（服务未运行，或账号无授权）</span>'); return; }
		var h = "";
		for(var j = 0; j < ids.length; j++){ h += badge(ids[j], "b-info"); }
		$("#model_box").html(h);
	});
});

/* ============================ 密钥管理 ============================ */
function loadKeys(){
	run(S.key, ["list"], {}, "workbuddy_key.json", function(d){
		if(!d.ok){ $("#key_empty").text("读取失败：" + (d.err || "")).show(); return; }
		var list = d.keys || [], html = "";
		for(var i = 0; i < list.length; i++){
			var k = list[i];
			var st = !k.enabled ? badge("已停用", "b-muted")
				: (k.expired ? badge("已过期", "b-err") : badge("可用", "b-ok"));
			var quota;
			if(k.token_quota > 0){
				var pct = Math.min(100, Math.round(k.token_used / k.token_quota * 100));
				quota = '<div class="wb-bar"><i style="width:' + pct + '%"></i></div><div class="wb-note">' + k.token_used + " / " + k.token_quota + "</div>";
			}else{
				quota = '<span class="wb-note">不限</span>';
			}
			var lim = [];
			if(k.max_ips) lim.push("IP数≤" + k.max_ips);
			if(k.ip_allow && k.ip_allow.length) lim.push("IP白名单 " + k.ip_allow.length + " 条");
			if(k.models && k.models.length) lim.push("模型 " + k.models.length + " 个");
			html += "<tr>"
				+ '<td data-l="名称">' + esc(k.name || "未命名") + '<div class="wb-note wb-mono">' + esc(k.prefix) + "…</div></td>"
				+ '<td data-l="状态">' + st + "</td>"
				+ '<td data-l="有效期">' + (k.expires_at ? ts(k.expires_at) : "永久") + "</td>"
				+ '<td data-l="配额">' + quota + "</td>"
				+ '<td data-l="限制">' + (lim.length ? esc(lim.join(" · ")) : "不限") + "</td>"
				+ '<td data-l="最近使用">' + ago(k.last_used_at) + "</td>"
				+ '<td data-l="操作"><button class="wb-btn mini" onclick="keyAct(\'' + k.id + '\',\'' + (k.enabled ? "disable" : "enable") + '\')">' + (k.enabled ? "停用" : "启用") + "</button> "
				+ '<button class="wb-btn mini danger" onclick="keyAct(\'' + k.id + '\',\'del\')">删除</button></td>'
				+ "</tr>";
		}
		$("#key_tb").html(html);
		$("#key_empty").toggle(list.length === 0).text("暂无密钥，点「新建密钥」创建第一把");
	});
}
function keyAct(id, act){
	if(act === "del" && !confirm("确认删除该密钥？使用它的客户端会立即失效。")) return;
	run(S.key, [act, "--id=" + id], {}, "workbuddy_key.json", function(d){
		toast(d.ok ? "操作成功" : ("失败：" + (d.err || "")), d.ok ? "ok" : "err");
		if(d.ok) loadKeys();
	});
}
$("#wb_btn_refresh_key").click(loadKeys);
$("#wb_btn_add_key").click(function(){
	modal("<h4>新建密钥</h4>"
		+ '<div class="wb-field"><label>名称</label><input class="wb-input" id="nk_name" placeholder="例如：手机"></div>'
		+ '<div class="wb-field"><label>有效天数</label><input class="wb-input" id="nk_days" value="0" style="max-width:120px"><span class="wb-hint">0=永久</span></div>'
		+ '<div class="wb-field"><label>最大来源 IP 数</label><input class="wb-input" id="nk_ips" value="0" style="max-width:120px"><span class="wb-hint">24h 内，0=不限</span></div>'
		+ '<div class="wb-field"><label>IP 白名单</label><input class="wb-input" id="nk_ip" placeholder="192.168.1.0/24，逗号分隔"></div>'
		+ '<div class="wb-field"><label>模型白名单</label><input class="wb-input" id="nk_models" placeholder="留空=不限"></div>'
		+ '<div class="wb-field"><label>Token 配额</label><input class="wb-input" id="nk_quota" value="0" style="max-width:160px"><span class="wb-hint">0=不限</span></div>'
		+ '<div class="wb-modal-foot"><button class="wb-btn" onclick="closeModal()">取消</button><button class="wb-btn primary" id="nk_ok">创建</button></div>');
	$("#nk_ok").click(function(){
		var $b = $(this).prop("disabled", true).text("创建中…");
		run(S.key, ["add",
			"--name=" + ($("#nk_name").val() || "未命名"),
			"--days=" + ($("#nk_days").val() || "0"),
			"--max-ips=" + ($("#nk_ips").val() || "0"),
			"--ip-allow=" + ($("#nk_ip").val() || ""),
			"--models=" + ($("#nk_models").val() || ""),
			"--quota=" + ($("#nk_quota").val() || "0")
		], {}, "workbuddy_key.json", function(d){
			if(!d.ok){
				$b.prop("disabled", false).text("创建");
				toast("创建失败：" + (d.err || ""), "err");
				return;
			}
			modal("<h4>密钥已创建</h4>"
				+ '<div class="wb-note">请立即复制保存 —— 关闭后无法再次查看明文。</div>'
				+ '<div class="wb-code" id="nk_plain">' + esc(d.plaintext) + "</div>"
				+ '<div class="wb-inline"><button class="wb-btn" onclick="copyText(\'nk_plain\')">复制</button></div>'
				+ '<div class="wb-modal-foot"><button class="wb-btn primary" onclick="closeModal();loadKeys();">我已保存</button></div>');
		});
	});
});
$("#wb_btn_policy").click(function(){
	run(S.key, ["policy", "show"], {}, "workbuddy_policy.json", function(d){
		var allow = (d.ip_allow || []).join(",");
		var deny = (d.ip_deny || []).join(",");
		modal("<h4>全局入站 IP 策略</h4>"
			+ '<div class="wb-field"><label>白名单</label><input class="wb-input" id="pl_allow" value="' + esc(allow) + '" placeholder="留空=不限制，支持 CIDR"></div>'
			+ '<div class="wb-field"><label>黑名单</label><input class="wb-input" id="pl_deny" value="' + esc(deny) + '" placeholder="支持 CIDR"></div>'
			+ '<div class="wb-note">白名单一旦填写，只放行其中的来源；黑名单优先级更高。</div>'
			+ '<div class="wb-modal-foot"><button class="wb-btn" onclick="closeModal()">取消</button><button class="wb-btn primary" id="pl_ok">保存</button></div>');
		$("#pl_ok").click(function(){
			run(S.key, ["policy", "set", "--ip-allow=" + $("#pl_allow").val(), "--ip-deny=" + $("#pl_deny").val()], {}, "workbuddy_policy.json", function(r){
				toast(r.ok ? "已保存" : ("失败：" + (r.err || "")), r.ok ? "ok" : "err");
				if(r.ok) closeModal();
			});
		});
	});
});

/* ============================ 统计与日志 ============================ */
function kpi(label, value, foot){
	return '<div class="wb-kpi"><div class="k-label">' + label + '</div><div class="k-value">' + value + '</div><div class="k-foot">' + foot + "</div></div>";
}
function loadStat(){
	var days = $("#stat_days").val() || "7";
	run(S.log, ["stat", "--days=" + days], {}, "workbuddy_stat.json", function(d){
		if(!d.ok){ $("#stat_grid").html('<div class="wb-note">读取失败：' + esc(d.err || "") + "</div>"); return; }
		var rate = (d.success_rate || 0).toFixed(1) + "%";
		$("#stat_grid").html(
			kpi("总调用", d.total, "成功 " + d.success + " · 失败 " + (d.total - d.success))
			+ kpi("成功率", rate, "近 " + days + " 天")
			+ kpi("平均首字延迟", (d.avg_first_ms || 0) + " ms", "从收到请求到首个字节")
			+ kpi("消耗积分", Math.round(d.credit_total || 0), "Token " + (d.prompt_tokens || 0) + " → " + (d.comp_tokens || 0))
		);
		function topBox(title, obj){
			var arr = [];
			for(var k in obj){ arr.push([k, obj[k]]); }
			if(!arr.length) return "";
			arr.sort(function(a, b){ return b[1] - a[1]; });
			var h = '<div class="wb-card" style="margin:0"><h3>' + title + '</h3><table class="wb-table">';
			for(var i = 0; i < Math.min(5, arr.length); i++){ h += "<tr><td>" + esc(arr[i][0] || "(空)") + "</td><td>" + arr[i][1] + "</td></tr>"; }
			return h + "</table></div>";
		}
		$("#stat_top").html(topBox("按密钥 Top 5", d.by_key || {}) + topBox("按模型 Top 5", d.by_model || {}));
	});
}
function loadLog(){
	var args = ["tail", "--n=" + ($("#log_n").val() || "200"), "--days=" + ($("#log_days").val() || "2")];
	if($("#log_err").prop("checked")) args.push("--err");
	run(S.log, args, {}, "workbuddy_log.json", function(d){
		if(!d.ok){ $("#log_empty").text("读取失败：" + (d.err || "")).show(); $("#log_tb").html(""); return; }
		var list = d.records || [], html = "";
		for(var i = 0; i < list.length; i++){
			var r = list[i];
			var cls = (r.status >= 200 && r.status < 300) ? "b-ok" : "b-err";
			var credit = (r.credit === undefined || r.credit < 0) ? "—" : r.credit;
			html += "<tr>"
				+ '<td data-l="时间">' + ts(r.ts) + "</td>"
				+ '<td data-l="密钥">' + esc(r.key_name || r.key_id || "-") + "</td>"
				+ '<td data-l="IP">' + esc(r.ip || "-") + "</td>"
				+ '<td data-l="模型">' + esc(r.model || "-") + "</td>"
				+ '<td data-l="状态">' + badge(r.status, cls) + "</td>"
				+ '<td data-l="首字">' + (r.first_byte_ms || 0) + "ms</td>"
				+ '<td data-l="耗时">' + (r.total_ms || 0) + "ms</td>"
				+ '<td data-l="Token">' + (r.prompt_tokens || 0) + "+" + (r.completion_tokens || 0) + "</td>"
				+ '<td data-l="积分">' + credit + "</td>"
				+ "</tr>";
		}
		$("#log_tb").html(html);
		$("#log_empty").toggle(list.length === 0).text(list.length ? "" : "暂无调用记录");
	});
}
$("#wb_btn_stat").click(loadStat);
$("#wb_btn_log").click(loadLog);
$("#stat_days").change(loadStat);
$("#wb_btn_log_clean").click(function(){
	run(S.log, ["clean"], {}, "workbuddy_log.json", function(d){
		toast(d.ok ? ("已清理 " + d.removed + " 个过期文件") : ("失败：" + (d.err || "")), d.ok ? "ok" : "err");
	});
});
$("#wb_btn_slog").click(function(){
	run(S.log, ["service"], {}, "workbuddy_servicelog.json", function(d){
		var lines = (d.lines || []).join("\n");
		$("#servicelog").text(lines || "（无日志）");
		if(d.path && !lines) $("#servicelog").text("日志文件：" + d.path + "（暂无内容）");
	});
});

/* ============================ 设置 ============================ */
var SET_FIELDS = [
	"workbuddy_listen_port", "workbuddy_upstream_port", "workbuddy_api_key", "workbuddy_data_dir",
	"workbuddy_audit_days", "workbuddy_audit_max_mb",
	"workbuddy_checkin_hours", "workbuddy_travel_hours", "workbuddy_activity_hours",
	"workbuddy_keepalive_hours", "workbuddy_school_hours", "workbuddy_cat_hours",
	"workbuddy_max_in_flight", "workbuddy_breaker_threshold", "workbuddy_breaker_cooldown",
	"workbuddy_breaker_cooldown_max", "workbuddy_soft_rate", "workbuddy_soft_rate_max",
	"workbuddy_expiring_soon", "workbuddy_sticky_ttl", "workbuddy_timeout", "workbuddy_prompt_mode"
];
var SET_SWITCHES = [
	"workbuddy_auto_start", "workbuddy_wan", "workbuddy_watchdog", "workbuddy_firewall",
	"workbuddy_checkin_enabled", "workbuddy_travel_enabled", "workbuddy_activity_enabled",
	"workbuddy_keepalive_enabled", "workbuddy_school_enabled", "workbuddy_cat_enabled",
	"workbuddy_sticky", "workbuddy_sanitize", "workbuddy_global_enabled"
];
var SET_DEFAULTS = {
	workbuddy_listen_port: "17863", workbuddy_upstream_port: "7863",
	workbuddy_data_dir: "/koolshare/etc/workbuddy", workbuddy_audit_days: "3", workbuddy_audit_max_mb: "2",
	workbuddy_checkin_hours: "9,21", workbuddy_travel_hours: "9,21", workbuddy_activity_hours: "10",
	workbuddy_keepalive_hours: "22", workbuddy_school_hours: "12", workbuddy_cat_hours: "1",
	workbuddy_max_in_flight: "3", workbuddy_breaker_threshold: "3", workbuddy_breaker_cooldown: "30m",
	workbuddy_breaker_cooldown_max: "6h", workbuddy_soft_rate: "600s", workbuddy_soft_rate_max: "2h",
	workbuddy_expiring_soon: "168h", workbuddy_sticky_ttl: "30m", workbuddy_timeout: "120",
	workbuddy_prompt_mode: "passthrough"
};
function fillSettings(){
	getDbus(function(m){
		function val(k){ return (m[k] === undefined || m[k] === "") ? SET_DEFAULTS[k] : m[k]; }
		for(var i = 0; i < SET_FIELDS.length; i++){ $("#" + SET_FIELDS[i]).val(val(SET_FIELDS[i])); }
		for(var j = 0; j < SET_SWITCHES.length; j++){ setChk(SET_SWITCHES[j], m[SET_SWITCHES[j]] === undefined ? "1" : m[SET_SWITCHES[j]]); }
		setChk("workbuddy_enable", m.workbuddy_enable === undefined ? "0" : m.workbuddy_enable);
		renderDiag();
	});
}
function collectFields(){
	var f = {};
	f.workbuddy_enable = chkVal("workbuddy_enable");
	for(var i = 0; i < SET_FIELDS.length; i++){ f[SET_FIELDS[i]] = $("#" + SET_FIELDS[i]).val(); }
	for(var j = 0; j < SET_SWITCHES.length; j++){ f[SET_SWITCHES[j]] = chkVal(SET_SWITCHES[j]); }
	return f;
}
function validateSettings(f){
	var ports = ["workbuddy_listen_port", "workbuddy_upstream_port"];
	for(var i = 0; i < ports.length; i++){
		var v = parseInt(f[ports[i]], 10);
		if(!(v >= 1 && v <= 65535)){ toast("端口必须是 1-65535", "err"); return false; }
	}
	var hours = ["workbuddy_checkin_hours", "workbuddy_travel_hours", "workbuddy_activity_hours",
		"workbuddy_keepalive_hours", "workbuddy_school_hours", "workbuddy_cat_hours"];
	for(var j = 0; j < hours.length; j++){
		var parts = String(f[hours[j]] || "").split(",");
		for(var k = 0; k < parts.length; k++){
			var p = $.trim(parts[k]);
			if(p === "") continue;
			var n = parseInt(p, 10);
			if(isNaN(n) || n < 0 || n > 23){ toast("定时时刻必须是 0-23 的整数：" + f[hours[j]], "err"); return false; }
		}
	}
	return true;
}
$("#wb_btn_save").click(function(){
	var f = collectFields();
	if(!validateSettings(f)) return;
	var $b = $(this).prop("disabled", true).text("保存中…");
	run(S.config, ["web_submit"], f, "workbuddy_action.json", function(d){
		$b.prop("disabled", false).text("保存并应用");
		toast(d.ok ? "已保存并应用" : ("保存失败：" + (d.err || "")), d.ok ? "ok" : "err");
		if(d.ok) setTimeout(function(){ fillSettings(); loadStatus(true); loadRuntime(); }, 2500);
	});
});
// 开关拨动即生效：软件中心判断「插件是否已开启」只看 dbus 的 workbuddy_enable，
// 卸载前必须先关掉它，所以这里不要等「保存并应用」。
$("#workbuddy_enable").change(function(){
	var v = chkVal("workbuddy_enable");
	$(this).prop("disabled", true);
	run(S.config, ["web_submit"], { workbuddy_enable: v }, "workbuddy_action.json", function(d){
		$("#workbuddy_enable").prop("disabled", false);
		if(!d.ok){ toast("切换失败：" + (d.err || ""), "err"); return; }
		toast(v === "1" ? "插件已启用" : "插件已关闭，现在可以卸载了", "ok");
		setTimeout(function(){ loadStatus(true); loadRuntime(); }, 2500);
	});
});
function svcAction(action, fields, tip){
	run(S.config, [action], fields, "workbuddy_action.json", function(d){
		toast(d.ok ? tip : (tip + "失败：" + (d.err || "")), d.ok ? "ok" : "err");
		setTimeout(function(){ loadStatus(true); loadRuntime(); }, 3000);
	});
}
$("#wb_btn_start").click(function(){ $("#workbuddy_enable").prop("checked", true); svcAction("start", { workbuddy_enable: "1" }, "已启动"); });
$("#wb_btn_stop").click(function(){ $("#workbuddy_enable").prop("checked", false); svcAction("stop", { workbuddy_enable: "0" }, "已停止"); });
$("#wb_btn_restart").click(function(){ svcAction("restart", {}, "已重启"); });
$("#wb_btn_migrate").click(function(){
	var dir = $.trim($("#workbuddy_data_dir").val());
	if(!dir){ toast("请先填写目标目录", "err"); return; }
	if(!confirm("确认把数据目录迁移到 " + dir + " ？迁移后会自动重启服务。")) return;
	var $b = $(this).prop("disabled", true).text("迁移中…");
	run(S.migrate, [dir], {}, "workbuddy_migrate.json", function(d){
		$b.prop("disabled", false).text("迁移到该目录");
		toast(d.ok ? "迁移完成，已重启服务" : ("迁移失败：" + (d.err || "")), d.ok ? "ok" : "err");
		if(d.ok) setTimeout(function(){ fillSettings(); loadStatus(true); }, 3000);
	});
});
$("#wb_btn_diag").click(function(){
	DIAG.post = null; DIAG.file = null; DIAG.dbus = null;
	renderDiag();
	loadStatus(true);
	// 再单独摸一次 dbus，把三格都点亮
	getDbus(function(){ renderDiag(); });
	toast("正在重新检测三条通道…", "info");
});
$("#wb_mask").click(function(e){ if(e.target === this) closeModal(); });

/* ============================ 标签与自动刷新 ============================ */
$(".wb-tab").click(function(){
	$(".wb-tab").removeClass("active");
	$(this).addClass("active");
	$(".wb-panel").removeClass("active");
	$("#" + $(this).attr("data-p")).addClass("active");
	var p = $(this).attr("data-p");
	if(p === "p_account") loadAccounts();
	else if(p === "p_key") loadKeys();
	else if(p === "p_log"){ loadStat(); loadLog(); }
	else if(p === "p_set") fillSettings();
	else loadStatus(true);
});
setInterval(function(){
	// 页面在后台、或上一次请求还没回来（比如正在 OAuth 轮询）就跳过本次自动刷新。
	// 注意：这里只是"跳过刷新"，任何用户点击的请求都一定会发出去。
	if(document.hidden || BUSY) return;
	if($("#p_status").hasClass("active")){ loadStatus(true); loadRuntime(); }
	else if($("#p_account").hasClass("active")) loadAccounts();
	else if($("#p_log").hasClass("active")) loadStat();
}, 30000);

/* ============================ 启动 ============================ */
fillSettings();
loadStatus(true);
loadRuntime();
loadStat();      // 状态页那两个 KPI（今日调用 / 消耗积分）靠它填
</script>
</body>
</html>

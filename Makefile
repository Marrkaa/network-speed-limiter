include $(TOPDIR)/rules.mk

PKG_NAME:=network-limiter
PKG_RELEASE:=1
PKG_VERSION:=1.0.0

include $(INCLUDE_DIR)/package.mk

define Package/network-limiter
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Network bandwidth limiter
	DEPENDS:=+tc +kmod-ifb
endef

define Package/network-limiter/description
	A bash script which can limit the network interface speed
endef

define Build/Compile

endef

define Package/network-limiter/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/network_limiter.sh $(1)/usr/sbin/

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/network_limiter.conf $(1)/etc/config/network_limiter
endef

$(eval $(call BuildPackage,network-limiter))